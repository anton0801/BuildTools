import Foundation
import Combine
import AdjustSdk

typealias CPSStep = (_ continuation: @escaping (CPSStepResult) -> Void) -> Void

enum CPSStepResult {
    case proceed
    case finalize(ToolboxOutcome)
    case failed(ToolboxError)
}

@MainActor
final class CPSEngine {
    
    let snapshots = SnapshotManager()
    
    private let outcomeSubject = PassthroughSubject<ToolboxOutcome, Never>()
    var outcomePublisher: AnyPublisher<ToolboxOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var sequenceCompleted: Bool = false
    
    private var vault: ToolboxVault { PhantomRegistry.shared.resolve(VaultMarker.self) }
    private var inspector: VoltageInspector { PhantomRegistry.shared.resolve(InspectorMarker.self) }
    private var refetcher: LockerRefetcher { PhantomRegistry.shared.resolve(RefetcherMarker.self) }
    private var charter: DockCharter { PhantomRegistry.shared.resolve(ChartMarker.self) }
    private var consenter: ConsentRequester { PhantomRegistry.shared.resolve(ConsentMarker.self) }
    
    func warmUp() {
        let frozen = vault.defrost()
        snapshots.replace(with: ToolboxSnapshot.hydrate(from: frozen))
    }
    
    func ingestLockers(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        snapshots.mutate { $0.with(lockers: mapped) }
        vault.stashLockers(mapped)
    }
    
    func ingestRoutes(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        snapshots.mutate { $0.with(routes: mapped) }
        vault.stashRoutes(mapped)
    }
    
    func ignite() {
        guard !sequenceCompleted else { return }
        
        runChain(steps: [
            stepPushShortCircuit,
            stepInspectVoltage,
            stepMaybeOrganic,
            stepChartDock
        ])
    }
    
    private func runChain(steps: [CPSStep]) {
        let composed = composeChain(steps: steps)
        composed { [weak self] result in
            Task { @MainActor [weak self] in
                self?.handleChainResult(result)
            }
        }
    }
    
    private func composeChain(steps: [CPSStep]) -> CPSStep {
        guard !steps.isEmpty else {
            return { continuation in continuation(.proceed) }
        }
        
        let first = steps[0]
        let rest = Array(steps.dropFirst())
        
        return { continuation in
            first { result in
                switch result {
                case .proceed:
                    if rest.isEmpty {
                        continuation(.proceed)
                    } else {
                        let nextChain = self.composeChain(steps: rest)
                        nextChain(continuation)
                    }
                case .finalize, .failed:
                    continuation(result)
                }
            }
        }
    }
    
    @MainActor
    private func handleChainResult(_ result: CPSStepResult) {
        switch result {
        case .proceed:
            break
        case .finalize(let outcome):
            sequenceCompleted = true
            outcomeSubject.send(outcome)
        case .failed(let err):
            sequenceCompleted = true
            outcomeSubject.send(.fallbackHome)
        }
    }
    
    private var stepPushShortCircuit: CPSStep {
        return { [weak self] continuation in
            guard let self = self else { return continuation(.proceed) }
            
            guard let tempURL = UserDefaults.standard.string(forKey: ToolboxKey.pushURL),
                  !tempURL.isEmpty else {
                continuation(.proceed)
                return
            }
            
            let needsConsent = self.snapshots.current.consentRipe
            
            self.snapshots.mutate {
                $0.with(
                    dockURL: tempURL,
                    dockMode: "Active",
                    untouched: false,
                    docked: true
                )
            }
            self.vault.stashDock(url: tempURL, mode: "Active")
            self.vault.markPrimed()
            UserDefaults.standard.removeObject(forKey: ToolboxKey.pushURL)
            
            let outcome: ToolboxOutcome = needsConsent ? .askForConsent : .openDock
            continuation(.finalize(outcome))
        }
    }
    
    private var stepInspectVoltage: CPSStep {
        return { [weak self] continuation in
            guard let self = self else { return continuation(.proceed) }
            
            guard self.snapshots.current.lockersFilled else {
                continuation(.proceed)
                return
            }
            
            let sequence = self.inspector.makeInspectionSequence()
            
            Task {
                do {
                    var verdict: Bool? = nil
                    
                    for try await event in sequence {
                        switch event {
                        case .probing:
                            continue
                        case .landed(let success):
                            verdict = success
                        }
                    }
                    
                    if verdict == true {
                        continuation(.proceed)
                    } else {
                        continuation(.failed(ToolboxError(.voltageInspectionFailed) {
                            ErrorTag(key: "result", value: "false")
                        }))
                    }
                } catch let err as ToolboxError {
                    continuation(.failed(err))
                } catch {
                    continuation(.failed(ToolboxError(.voltageInspectionFailed) {
                        ErrorTag(key: "underlying", value: "\(error)")
                    }))
                }
            }
        }
    }
    
    private var stepMaybeOrganic: CPSStep {
        return { [weak self] continuation in
            guard let self = self else { return continuation(.proceed) }
            
            let snap = self.snapshots.current
            
            guard snap.organicLane && snap.untouched && !snap.organicProbed else {
                continuation(.proceed)
                return
            }
            
            self.snapshots.mutate { $0.with(organicProbed: true) }
            
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                
                let stillUntouched = await MainActor.run {
                    !self.snapshots.current.docked
                }
                
                guard stillUntouched else {
                    continuation(.proceed)
                    return
                }
                
                let deviceID = await Adjust.adid() ?? ""
                
                do {
                    var fetched = try await self.refetcher.refetch(deviceID: deviceID)
                    
                    let routes = await MainActor.run { self.snapshots.current.routes }
                    for (k, v) in routes {
                        if fetched[k] == nil {
                            fetched[k] = v
                        }
                    }
                    
                    let mapped = fetched.mapValues { "\($0)" }
                    await MainActor.run {
                        self.snapshots.mutate { $0.with(lockers: mapped) }
                    }
                    self.vault.stashLockers(mapped)
                } catch {
                }
                
                continuation(.proceed)
            }
        }
    }
    
    private var stepChartDock: CPSStep {
        return { [weak self] continuation in
            guard let self = self else { return continuation(.proceed) }
            
            guard self.snapshots.current.lockersFilled else {
                continuation(.proceed)
                return
            }
            
            let lockers = self.snapshots.current.lockers
            let seed = lockers.mapValues { $0 as Any }
            
            Task {
                do {
                    let url = try await self.charter.chart(seed: seed)
                    
                    await MainActor.run {
                        let needsConsent = self.snapshots.current.consentRipe
                        
                        self.snapshots.mutate {
                            $0.with(
                                dockURL: url,
                                dockMode: "Active",
                                untouched: false,
                                docked: true
                            )
                        }
                        self.vault.stashDock(url: url, mode: "Active")
                        self.vault.markPrimed()
                        UserDefaults.standard.removeObject(forKey: ToolboxKey.pushURL)
                        
                        let outcome: ToolboxOutcome = needsConsent ? .askForConsent : .openDock
                        continuation(.finalize(outcome))
                    }
                } catch let err as ToolboxError {
                    continuation(.failed(err))
                } catch {
                    continuation(.failed(ToolboxError(.wireSnapped) {
                        ErrorTag(key: "underlying", value: "\(error)")
                    }))
                }
            }
        }
    }
    
    func acceptConsent(callback: @escaping () -> Void) {
        let priorArmed = snapshots.current.consentArmed
        let priorBarred = snapshots.current.consentBarred
        
        consenter.request { [weak self] granted in
            guard let self = self else { return }
            
            let now = Date()
            
            self.snapshots.mutate {
                if granted {
                    return $0.with(
                        consentArmed: true,
                        consentBarred: false,
                        consentClockedAt: .some(now)
                    )
                } else {
                    return $0.with(
                        consentArmed: false,
                        consentBarred: true,
                        consentClockedAt: .some(now)
                    )
                }
            }
            
            if granted { self.consenter.arm() }
            
            _ = priorArmed
            _ = priorBarred
            
            callback()
            self.vault.stashConsent(armed: granted, barred: !granted, at: now)
            self.outcomeSubject.send(.openDock)
        }
    }
    
    func deferConsent() {
        let now = Date()
        let armed = snapshots.current.consentArmed
        let barred = snapshots.current.consentBarred
        
        snapshots.mutate { $0.with(consentClockedAt: .some(now)) }
        vault.stashConsent(armed: armed, barred: barred, at: now)
        
        outcomeSubject.send(.openDock)
    }
    
    func reportDeadlineHit() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
}
