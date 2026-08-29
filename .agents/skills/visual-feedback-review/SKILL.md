---
name: visual-feedback-review
description: Review and act on saved visual feedback artifacts such as screenshots, marked-up images, JSON metadata, camera states, viewport sizes, drawing strokes, and local viewer URLs. Use when a user points to feedback, says they circled or marked something, reports a visual defect, asks to fix a model/UI based on a screenshot, or corrects a previous interpretation of visual feedback.
---

# Visual Feedback Review

Use this workflow before editing code, geometry, CSS, or assets based on visual feedback.

## Required Workflow

1. Load the raw feedback artifacts first: screenshot/image, JSON metadata, note text, viewport, camera/target/up/zoom, selected model/file, and any stroke coordinates.
2. Reproduce the feedback view before diagnosing. Use the same camera, target, viewport, model, render mode, overlays, selected file, and generated asset URL when the metadata provides them.
3. Inspect the marked region itself. Distinguish user-drawn strokes from model geometry, UI overlays, preview helpers, shadows, grid lines, and viewer artifacts.
4. Describe the problem back to the user in concrete visual terms before making a risky fix. Mention the specific marked region, side, orientation, and likely source only when supported by the artifacts.
5. If the user confirms or the fix is straightforward, make the smallest structural change that addresses the marked defect. Avoid broad removals, unrelated refactors, and cosmetic cover-ups unless the user explicitly wants a visual patch.
6. Verify from the same feedback view after editing. Do not call the work done from a different camera angle, a different viewport, or only from a build/export success.

## Guardrails

- Never assume a symmetric object means the opposite side is equivalent. If the saved camera is on the left/rear/front side, validate that same side.
- Do not treat `Simple: yes`, a successful test, or a clean export as visual confirmation. It only proves technical validity.
- Do not change unrelated parts that merely look similar. If the user circled a slot, do not remove wheels, axles, bosses, screw holes, or preview overlays unless those are the defect.
- Do not add cover-up geometry when the user asks for a solid/consistent underlying structure. Fix the generating boolean, profile, wall thickness, or source geometry instead.
- Preserve user changes in dirty files. Stage or commit only files explicitly requested.

## Visual Feedback Checklist

Before editing:

- Identify the exact artifact path or URL used for feedback.
- Open the screenshot at high or original detail.
- Extract camera and viewport from metadata when available.
- State what the user circled, including what it is not.
- Name the likely responsible module/component only after mapping it to the marked region.

After editing:

- Render or run the app through the same pipeline used to create the feedback.
- Capture or inspect the same camera/view.
- Compare the marked region, not a convenient alternate angle.
- Report remaining ambiguity instead of claiming success from incomplete validation.
