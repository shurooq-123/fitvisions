# Measured avatar and controlled comparison

## Implemented locally
- Coordinates in centimetres; a triangle mesh, not a painted silhouette.
- Height is max vertex y minus min vertex y. Chest, waist and hips are named torso mesh loops. Their polygon perimeters are scaled to the requested numbers.
- Fixed section depth/width ratio 0.68. Head, limbs, shoulder position and vertical landmarks are assumptions. Weight is not used to invent anatomy. This is a neutral featureless mannequin, not a body scan or cloth simulation.
- The rendered image can be saved to existing history and downloaded through the existing demo subscription flow. Ready-made clothing keeps its existing AI preview route.
- Tests generate front/side PNGs, OBJ meshes and an audit at `output/measured-avatar/`. These synthetic test cases do not use personal photos or cloud APIs.

## Cloud comparison: live synthetic case completed
The bridge was initially offline; the user reconnected the credential locally. Automatic approval review initially rejected personal-photo/measurement export. The user subsequently explicitly approved sending selected photos and measurements to Cloudflare; the comparison UI and bridge model allowlist have now been implemented. A synthetic mannequin and bundled Omani garment were compared through both candidates. No real-person photo was used in this first live case. No general winner or centimetre-accuracy claim is made. Live outputs and per-run timings are in output/avatar-model-comparison/report.json and repeat-2/report.json, repeat-3/report.json.

Prepared candidates, both on the same provider for a controlled first evaluation:
- FLUX.2 klein 4B: https://developers.cloudflare.com/workers-ai/models/flux-2-klein-4b/
- FLUX.2 klein 9B: https://developers.cloudflare.com/workers-ai/models/flux-2-klein-9b/
These are image generation/editing models, not dimension-constrained body reconstruction systems.

## Protocol after approval and reconnection
1. Freeze a case containing cm measurements, the neutral mannequin front image, and the user's chosen garment and personal photos. Strip metadata and create one identical resized reference set for both candidates.
2. Use identical prompt, dimensions, reference order, output resolution and seed where supported. Repeat each case three times; report provider/model/version and failures. A shared seed does not make distinct models deterministic equivalents.
3. Record wall time and result images. Human review scores separately: body silhouette resemblance, garment cut, sleeve/neckline details, colour, face resemblance, image defects (1–5, score definitions in the next table).
4. Preserve originals and blind candidate labels during review. Report the per-case results and failure rate, not only an average or an attractive sample.
5. Image-space resemblance is NOT a cm measurement. Cloud image outputs cannot be certified dimension-exact from a single rendered view. Keep geometric audit as a separate metric; do not combine it into an invented accuracy percentage.
6. Choose a service only after measured results and cost/latency are available. Do not upload photos until explicit consent to Cloudflare is obtained.

| Review score | Meaning |
| --- | --- |
| 1 | Requested feature missing or seriously altered |
| 3 | Recognizable but visibly altered |
| 5 | No obvious difference in the reviewed feature at the available resolution |

The same four measurements admit many real body shapes. A higher-fidelity personal model needs additional dimensions or calibrated scans and validated reconstruction; neither is claimed by this prototype.
