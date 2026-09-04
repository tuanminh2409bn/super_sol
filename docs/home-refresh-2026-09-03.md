# SuperSOL Home: content and icons refresh — 2026-09-03

## Scope

The Home presentation in `lib/ui/home_screen.dart` is refreshed while existing account data, PIN and transfer logic remain unchanged. The account-history screen also adds the requested `잔액` switch: blue/right displays each transaction's running balance, while gray/left hides only those running-balance labels. The account's main balance remains visible in both states. No backend, Firebase data, Booking code, release configuration, version, or deployment changes were made.

The September reference supplies coupon copy, spending heading/caption, insurance copy, the three recommended services, and icon subjects. New captions use spare space inside existing sections, without adding or resizing cards. The original side-positioned coupon action stays in place. The original header still collapses after scrolling past its existing threshold.

## Preview images from actual Flutter rendering

- `test/goldens/3_4_home_september_benefits.png`: coupon, spending, insurance and points at scroll offset 455.
- `test/goldens/3_3_services_scrolled.png`: points, recommendations, financial group and footer at offset 1108; header collapsed according to existing behavior.
- `test/goldens/3_1_home.png`: initial Home, retaining account and bank cards.
- `test/goldens/3_2_services.png`: continuation with header still visible, offset 941.

These are Flutter golden renders at the existing 589 × 1280 design canvas, not screenshots from a physical phone and not AI-generated whole-screen previews.

## Assets and generation prompts

Three replacement illustrations were generated using the built-in ImageGen tool, with the user images as references. The alpha channel is preserved. Old assets remain in the repository. Illustrations are reconstructions, not pixel-identical extracts.

### Delivery scooter

Saved asset: `/Volumes/Developer/DevEnv/Projects/app_hq/assets/images/home_delivery_scooter.png`

Original prompt:

> Use case: background-extraction. Asset type: transparent PNG UI illustration. Recreate ONLY the small red-orange delivery scooter illustration beside the coupon offer in the supplied screenshot. Input screenshot is exact visual reference. Isolate scooter with delivery box, black two wheels, tiny white squares on rear box, facing right, subtle 3D rounded emoji-like styling. No text, no UI, no card, no background. Genuine transparent alpha background. Centered tightly in a landscape 3:2 canvas with only 5 percent transparent padding, whole scooter visible. Match reference colors and recognizable silhouette, clean edges for use at 58x39 logical pixels in an existing app.

Final correction prompt, applied to the first generated scooter:

> Use case: background-extraction. This image has an incorrect baked-in checkerboard. Remove all white and gray checkerboard pixels OUTSIDE the red scooter and return a PNG with genuine TRANSPARENT ALPHA, not a checkerboard illustration, not a white background. Preserve only the red scooter, white box squares, body, and black wheels. Crop the canvas very tightly to the scooter bounds leaving 2 percent transparent margin. The scooter should occupy 96 percent of canvas width. No extra text, no UI, no background pattern.

### Insurance ribbon

Saved asset: `/Volumes/Developer/DevEnv/Projects/app_hq/assets/images/home_insurance_ribbon.png`

Prompt:

> Use case: background-extraction. Asset type: transparent PNG illustration. Recreate ONLY the glossy blue awareness ribbon with translucent blue bubbles shown at the right of the insurance advertisement in reference screenshot. All other screenshot content must be absent. Blue folded loop at top, crossed flowing ribbon tails at bottom, matching highlights and light translucent spheres as original. Genuine transparent alpha background, no text, no frame, no UI, no cast square background. Centered tightly with entire ribbon and bubbles visible, 5 percent transparent edge padding, approximately square canvas. This replaces a 128x133 logical-pixel insurance promo illustration in an existing app.

### Coupon tile

Saved asset: `/Volumes/Developer/DevEnv/Projects/app_hq/assets/images/home_service_coupon.png`

Prompt:

> Use case: background-extraction. Asset type: small app UI image asset. Isolate and faithfully recreate ONLY the coupon tile icon at the left of the 내 쿠폰함 row in supplied screenshot: light lavender-gray rounded square tile, blue rectangular coupon ticket with centered white five-point star, darker blue right stub with notch/fold. Match flat simple icon treatment of the existing salary envelope and payment card icons. Genuine transparent alpha outside the rounded square tile, no text, no other UI. Tile fills almost entire square canvas, about 5 percent transparent border; intended use at 72x77 logical pixels. Not an entire app screenshot.

Product, gift and stock navigation glyphs are code-native Canvas shapes, keeping the existing 31-pixel IconTheme size and colors. Pin icons use the existing Material icon, rotated to match the references.

## Verification

- `flutter test`: **75/75 passed**, including the `잔액` switch behavior, Home scroll, typography/dimensions, long account names, account/PIN/transfer regressions and golden renders.
- `flutter analyze`: no issues found.
- `git diff --check`: passed.
- Inspected the rendered Home images for asset alpha, copy fit and icon appearance.
- Three existing history tests needed an explicit `nowProvider` of 2026-08-27 to match their fixed transaction fixtures; those fixture updates were test-only.
- Built and installed the debug APK on a connected Samsung SM-A366B. The `잔액` switch was tapped off and on in a signed-in account with real local history data; screenshots confirmed that only the per-transaction running balances disappear and return. No production Android or iOS release was published in this task.
