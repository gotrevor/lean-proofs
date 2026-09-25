import Lake

open System Lake DSL

package «lean-proofs-latest» where
  version := v!"0.1.0"
  keywords := #["math"]
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`relaxedAutoImplicit, false⟩,
    ⟨`weak.linter.mathlibStandardSet, true⟩,
    ⟨`maxSynthPendingDepth, 3⟩
  ]

require leancert from git "https://github.com/alerad/leancert.git" @ "v4.33.1"

require ComparatorChallenges from "ComparatorChallenges"

require APAP from git "https://github.com/YaelDillies/apap.git" @ "v4.33.0"

require AINTLIB from git "https://github.com/CBirkbeck/AINTLIB.git" @
  "1c1c74664e40071c2c2165bc55ca2616a67ccd6b"

require BoundedGaps from git "https://github.com/gotrevor/FormalPantheon.git" @
  "9a973bb8bc254720a2fcb8436bc5984b1cf21e82" / "BoundedGaps"

require Waring from git "https://github.com/gotrevor/FormalPantheon.git" @
  "9a973bb8bc254720a2fcb8436bc5984b1cf21e82" / "Warning"

require PrimeNumberTheoremAnd from git
  "https://github.com/AlexKontorovich/PrimeNumberTheoremAnd.git" @
  "55270df807213fc3584523d09e0311d7dc073ff5"

require mathlib from git "https://github.com/leanprover-community/mathlib4.git" @ "v4.33.1"

@[default_target] lean_lib All

lean_lib Arxiv

lean_lib BorisBukh

lean_lib ErdosProblems

lean_lib HundredTheorems

lean_lib MathOverflow

lean_lib StackExchange

lean_lib Util

lean_lib UnitFractions

lean_lib Wikipedia

private def runGitApply
    (directory patch : FilePath) (arguments : Array String) : IO IO.Process.Output :=
  IO.Process.output {
    cmd := "git"
    args := #["-C", directory.toString, "apply"] ++ arguments ++ #[patch.toString]
  }

post_update pkg do
  for (name, patchName) in #[
      ("BoundedGaps", "formalpantheon-v4.33.0.patch"),
      ("BoundedGaps", "formalpantheon-v4.33.0-s2.patch"),
      ("BoundedGaps", "boundedgaps-linter-v4.33.0.patch"),
      ("AINTLIB", "aintlib-v4.33.0.patch"),
      ("AINTLIB", "hasseweil-linter-v4.33.0.patch"),
      ("AINTLIB", "chebotarev-linter-v4.33.0.patch"),
      ("AINTLIB", "dedekind-flt-linter-v4.33.0.patch"),
      ("Waring", "waring-linter-v4.33.0.patch")] do
    -- Dependencies live in the ROOT workspace's package directory, which is this package's own
    -- `.lake/packages` only when this package is the root.
    let dependency := (← getRootPackage).dir / ".lake" / "packages" / name
    let patch := pkg.dir / "patches" / patchName
    if !(← dependency.pathExists) then
      error s!"{name} package directory does not exist: {dependency}"
    if !(← patch.pathExists) then
      error s!"{name} compatibility patch does not exist: {patch}"
    let forwardCheck ← runGitApply dependency patch #["--check"]
    if forwardCheck.exitCode = 0 then
      let result ← runGitApply dependency patch #[]
      if result.exitCode != 0 then
        error s!"failed to apply {name} compatibility patch {patch}:\n{result.stderr}"
      IO.println s!"Applied {name} compatibility patch {patchName}."
    else
      let reverseCheck ← runGitApply dependency patch #["--reverse", "--check"]
      if reverseCheck.exitCode = 0 then
        IO.println s!"{name} compatibility patch {patchName} is already applied."
      else
        error s!"{name} checkout is incompatible with compatibility patch {patch}.\n\
          Forward check:\n{forwardCheck.stderr}\nReverse check:\n{reverseCheck.stderr}"
