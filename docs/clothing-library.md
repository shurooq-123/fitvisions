# Bundled garment references

Generated with the built-in image_gen tool, 2026-10-01. These are illustrative designs, not products for sale or an exhaustive representation of Omani regional dress.

Assets are bundled through the existing images/ entry in pubspec.yaml. Viewing and selecting needs no network. AI generation still uses the normal explicit confirmation and online service. References work in avatar generation, avatar clothing replacement, and clothing creation. Asset paths saved with measurements render through SavedImage.

Prompt set (common: product catalog photography, invisible mannequin, full front view, warm gray studio background, no text or watermark):
- omani_men.png: white Omani dishdasha, round collarless neckline, furakha tassel, long sleeves, embroidered kumma beside it.
- omani_women.png: Omani-inspired burgundy embroidered knee-length tunic, gold neckline/cuffs, matching sirwal with embroidered ankles and coordinating shawl.
- bridal_lace.png: white princess ball gown, high neckline, long lace sleeves, embroidered bodice, tulle skirt and short train.
- bridal_satin.png: ivory satin wedding dress, off-shoulder neckline, fitted waist, A-line skirt, minimal pearl detail and short train.
- omani_groom.png: Omani groom wearing white dishdasha with furakha, wrapped embroidered massar and open black bisht with gold trim; featureless mannequin, full front studio view. Generated with built-in image_gen.

## Collections update — 2026-10-05

Ready-made outfits now starts with three collections: Traditional Clothes, Wedding, and Professional Clothes. Each collection requires Male/Female selection before showing garments. Selection resets on gender changes. Traditional male accessories remain configurable; the wedding groom includes Massar and Bisht. Female wedding options have ball gown, mermaid and A-line silhouettes. Professional references include engineer, doctor, nurse and chef for each gender.

The new 14 assets are generated product illustrations with clothing only, no visible human/head/avatar. Catalog metadata lives in lib/widgets/outfit_catalog.dart. Legacy files remain for existing saved paths but are not listed in the new catalog. The modal library uses the same collection and gender filters; when opened from a gender-specific Create Clothes form it keeps that gender.

Create Clothes removes Colour palette, retains Favourite colour, and adds an optional camera/gallery face reference with preview and removal. The selected face is supplied last to the existing generation request; the prompt distinguishes it from the garment. With no face, output remains a headless product display. Existing pre-generation disclosure identifies Cloudflare and selected photos. Face upload does not itself invoke AI or save the source face in Firestore.

Validation: Flutter analyzer passed before final asset import. Added collection/gender/face-field regression tests; Flutter test and APK compilation remain blocked by the previously confirmed Windows Application Control restriction. Actual model face fidelity, UI rendering, and installation of this update are not verified.
