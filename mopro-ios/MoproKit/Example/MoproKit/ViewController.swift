//
//  ViewController.swift
//  MoproKit
//
//  Created by 1552237 on 09/16/2023.
//  Copyright (c) 2023 1552237. All rights reserved.
//

import UIKit
import MoproKit

class ViewController: UIViewController {

    var proveButton = UIButton(type: .system)
    var verifyButton = UIButton(type: .system)
    var textView = UITextView()
    let moproCircom = MoproKit.MoproCircom()
    var setupResult: SetupResult?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        runSetup()
    }

    func runSetup() {
        if let wasmPath = Bundle.main.path(forResource: "multiplier2", ofType: "wasm"),
           let r1csPath = Bundle.main.path(forResource: "multiplier2", ofType: "r1cs") {
            do {
                setupResult = try moproCircom.setup(wasmPath: wasmPath, r1csPath: r1csPath)
                proveButton.isEnabled = true // Enable the Prove button upon successful setup
            } catch let error as MoproError {
                print("MoproError: \(error)")
            } catch {
                print("Unexpected error: \(error)")
            }
        } else {
            print("Error getting paths for resources")
        }
    }

    func setupUI() {
        self.title = "MoproKit Demo"
        view.backgroundColor = .white

        proveButton.setTitle("Prove", for: .normal)
        verifyButton.setTitle("Verify", for: .normal)
        textView.isEditable = false

        // Make buttons bigger
        proveButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        verifyButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        proveButton.addTarget(self, action: #selector(runProveAction), for: .touchUpInside)
        verifyButton.addTarget(self, action: #selector(runVerifyAction), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [proveButton, verifyButton, textView])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Make text view visibile
        textView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }

    @objc func runProveAction() {
        guard let setupResult = setupResult else {
            print("Setup is not completed yet.")
            return
        }
        do {

            // Prepare inputs
            var inputs = [String: [Int32]]()
            inputs["a"] = [3]
            inputs["b"] = [5]

            // Record start time
            let start = CFAbsoluteTimeGetCurrent()

            // Generate Proof
            let generateProofResult = try moproCircom.generateProof(circuitInputs: inputs)
            assert(!generateProofResult.proof.isEmpty, "Proof should not be empty")

            // Record end time and compute duration
            let end = CFAbsoluteTimeGetCurrent()
            let timeTaken = end - start

            textView.text += "Proof generation took \(timeTaken) seconds.\n"
            verifyButton.isEnabled = true // Enable the Verify button once proof has been generated
        } catch let error as MoproError {
            print("MoproError: \(error)")
        } catch {
            print("Unexpected error: \(error)")
        }
    }

    @objc func runVerifyAction() {
        guard let setupResult = setupResult else {
            print("Setup is not completed yet.")
            return
        }
        do {

            // Re-prepare inputs (you might want to store the inputs to reuse them)
            var inputs = [String: [Int32]]()
            inputs["a"] = [3]
            inputs["b"] = [5]

            // Re-generate Proof (ideally, you should store and reuse the generateProofResult)
            let generateProofResult = try moproCircom.generateProof(circuitInputs: inputs)
            assert(!generateProofResult.proof.isEmpty, "Proof should not be empty")

            let proof = generateProofResult.proof
            let publicInputs = generateProofResult.inputs

            // Verify Proof
            let isValid = try moproCircom.verifyProof(proof: proof, publicInput: publicInputs)
            assert(isValid, "Proof verification should succeed")

            textView.text += "Proof verification succeeded.\n"
        } catch let error as MoproError {
            print("MoproError: \(error)")
        } catch {
            print("Unexpected error: \(error)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
