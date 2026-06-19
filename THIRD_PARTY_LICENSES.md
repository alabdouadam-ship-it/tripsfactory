# Third-Party Licenses & Notices

This product bundles or depends on third-party software and assets, each
governed by its own license. The list below is provided to help you (the
Licensee) meet attribution and compliance obligations for your application.

> **How to regenerate the dependency list**
> - Flutter / Dart: `flutter pub deps --style=compact` (or inspect `pubspec.lock`).
>   For machine-readable license text, the `flutter_oss_licenses` package can
>   generate a bundled notices screen.
> - Admin (Node): `npx license-checker --summary` from the `admin/` folder.
>
> Verify the exact license and version of each package against its repository
> before publishing, as versions and licenses can change.

---

## 1. Flutter / Dart packages (`pubspec.yaml`)

All packages below are published on [pub.dev](https://pub.dev). Most use the
permissive **BSD-3-Clause** or **MIT** license; confirm per package and version.

### Runtime dependencies

| Package | Typical license | Project |
|---|---|---|
| flutter (SDK) | BSD-3-Clause | https://github.com/flutter/flutter |
| flutter_localizations (SDK) | BSD-3-Clause | https://github.com/flutter/flutter |
| cupertino_icons | MIT | https://pub.dev/packages/cupertino_icons |
| intl | BSD-3-Clause | https://pub.dev/packages/intl |
| supabase_flutter | MIT | https://pub.dev/packages/supabase_flutter |
| flutter_riverpod | MIT | https://pub.dev/packages/flutter_riverpod |
| go_router | BSD-3-Clause | https://pub.dev/packages/go_router |
| google_fonts | Apache-2.0 | https://pub.dev/packages/google_fonts |
| flutter_dotenv | MIT | https://pub.dev/packages/flutter_dotenv |
| flutter_animate | MIT | https://pub.dev/packages/flutter_animate |
| geolocator | MIT | https://pub.dev/packages/geolocator |
| shimmer | BSD-3-Clause | https://pub.dev/packages/shimmer |
| shared_preferences | BSD-3-Clause | https://pub.dev/packages/shared_preferences |
| url_launcher | BSD-3-Clause | https://pub.dev/packages/url_launcher |
| share_plus | BSD-3-Clause | https://pub.dev/packages/share_plus |
| app_links | MIT | https://pub.dev/packages/app_links |
| firebase_core | BSD-3-Clause | https://pub.dev/packages/firebase_core |
| firebase_messaging | BSD-3-Clause | https://pub.dev/packages/firebase_messaging |
| firebase_analytics | BSD-3-Clause | https://pub.dev/packages/firebase_analytics |
| flutter_local_notifications | BSD-3-Clause | https://pub.dev/packages/flutter_local_notifications |
| dropdown_button2 | MIT | https://pub.dev/packages/dropdown_button2 |
| cached_network_image | MIT | https://pub.dev/packages/cached_network_image |
| in_app_review | MIT | https://pub.dev/packages/in_app_review |
| record | BSD-3-Clause | https://pub.dev/packages/record |
| audioplayers | MIT | https://pub.dev/packages/audioplayers |
| path_provider | BSD-3-Clause | https://pub.dev/packages/path_provider |
| permission_handler | MIT | https://pub.dev/packages/permission_handler |
| uuid | MIT | https://pub.dev/packages/uuid |
| image_picker | Apache-2.0 | https://pub.dev/packages/image_picker |
| path | BSD-3-Clause | https://pub.dev/packages/path |
| flutter_secure_storage | BSD-3-Clause | https://pub.dev/packages/flutter_secure_storage |
| file_picker | MIT | https://pub.dev/packages/file_picker |
| freezed_annotation | MIT | https://pub.dev/packages/freezed_annotation |
| json_annotation | BSD-3-Clause | https://pub.dev/packages/json_annotation |
| connectivity_plus | BSD-3-Clause | https://pub.dev/packages/connectivity_plus |
| package_info_plus | BSD-3-Clause | https://pub.dev/packages/package_info_plus |
| flutter_markdown | BSD-3-Clause | https://pub.dev/packages/flutter_markdown |

### Dev / build-time dependencies (not shipped in the app binary)

| Package | Typical license | Project |
|---|---|---|
| flutter_test (SDK) | BSD-3-Clause | https://github.com/flutter/flutter |
| integration_test (SDK) | BSD-3-Clause | https://github.com/flutter/flutter |
| mocktail | MIT | https://pub.dev/packages/mocktail |
| yaml | MIT | https://pub.dev/packages/yaml |
| image | MIT | https://pub.dev/packages/image |
| http | BSD-3-Clause | https://pub.dev/packages/http |
| flutter_lints | BSD-3-Clause | https://pub.dev/packages/flutter_lints |
| flutter_launcher_icons | MIT | https://pub.dev/packages/flutter_launcher_icons |
| build_runner | BSD-3-Clause | https://pub.dev/packages/build_runner |
| freezed | MIT | https://pub.dev/packages/freezed |
| json_serializable | BSD-3-Clause | https://pub.dev/packages/json_serializable |

---

## 2. Admin panel — Node packages (`admin/package.json`)

Next.js app. Most packages are **MIT**; confirm per package and version.

### Runtime dependencies

| Package | Typical license | Project |
|---|---|---|
| @supabase/supabase-js | MIT | https://github.com/supabase/supabase-js |
| @types/leaflet | MIT | https://www.npmjs.com/package/@types/leaflet |
| clsx | MIT | https://github.com/lukeed/clsx |
| leaflet | BSD-2-Clause | https://github.com/Leaflet/Leaflet |
| lucide-react | ISC | https://github.com/lucide-icons/lucide |
| next | MIT | https://github.com/vercel/next.js |
| react | MIT | https://github.com/facebook/react |
| react-dom | MIT | https://github.com/facebook/react |
| react-leaflet | Hippocratic-2.1 | https://github.com/PaulLeCam/react-leaflet |
| recharts | MIT | https://github.com/recharts/recharts |
| tailwind-merge | MIT | https://github.com/dcastil/tailwind-merge |

> **Note on `react-leaflet`:** recent versions use the Hippocratic License
> (an ethical-use license). Review its terms to confirm they are acceptable for
> your distribution, or pin to a compatible version.

### Dev dependencies (build/test only)

| Package | Typical license | Project |
|---|---|---|
| @tailwindcss/postcss, tailwindcss | MIT | https://github.com/tailwindlabs/tailwindcss |
| @testing-library/* | MIT | https://github.com/testing-library |
| @vitejs/plugin-react | MIT | https://github.com/vitejs/vite-plugin-react |
| @types/node, @types/react, @types/react-dom | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped |
| eslint, eslint-config-next | MIT | https://github.com/eslint/eslint |
| jsdom | MIT | https://github.com/jsdom/jsdom |
| typescript | Apache-2.0 | https://github.com/microsoft/TypeScript |
| vitest | MIT | https://github.com/vitest-dev/vitest |

---

## 3. Map data & tiles — OpenStreetMap (attribution required)

The admin panel renders maps with **Leaflet** / **react-leaflet** using map
tiles. If you use the default OpenStreetMap tile server you **must**:

1. **Display attribution** on every map: “© OpenStreetMap contributors”,
   linked to https://www.openstreetmap.org/copyright (ODbL 1.0).
2. **Comply with the OSM tile usage policy**:
   https://operations.osmfoundation.org/policies/tiles/ — the public tile
   servers are **not** for heavy/production traffic.

**For production, use a commercial tile provider** (e.g. MapTiler, Mapbox,
Stadia Maps, Thunderforest) and follow that provider's attribution and license
terms.

> **Scope of this product:** this product ships only its own (free) source code
> and uses the default free OpenStreetMap tiles for demonstration. It does not
> resell map tiles or any tile-provider subscription. The buyer is responsible
> for choosing a tile provider and complying with that provider's attribution,
> usage, and pricing terms for their production traffic.

---

## 4. Fonts

- **Google Fonts** are loaded via the `google_fonts` package. Fonts served by
  Google Fonts are open-source (typically **SIL Open Font License 1.1** or
  **Apache-2.0**). Confirm the license of the specific family you ship and keep
  the OFL/Apache notice if you bundle font files.
- **Material Icons** font (bundled by Flutter `uses-material-design: true`) —
  Apache-2.0.

> **Action for the seller:** confirm the exact font families configured in your
> theme/font config and include their OFL/Apache license text if the font files
> are bundled in the app.

---

## 5. Bundled assets

The visual/audio assets shipped with the product — app/launcher icons
(`assets/icon/`), the in-app notification sound, and bundled fonts — were
generated with AI image/asset tools under a licensed subscription (or are
otherwise openly licensed) and are licensed for redistribution as part of this
product.

When you rebrand, you will typically replace these with your own assets anyway
(see the icon-replacement guide in `docs/GETTING_STARTED.md`). If you add any
new third-party asset, confirm its license permits redistribution in a sold
product before bundling it.

---

## 6. Backend services (not redistributed; buyer provisions their own)

These are services your application connects to. The buyer provisions their own
accounts; their use is governed by the provider's terms — no code is bundled
beyond the client SDKs listed above.

- **Supabase** — https://supabase.com/terms
- **Firebase / Google Cloud** (Messaging, Analytics) — https://firebase.google.com/terms

---

_Last reviewed: regenerate this file with the commands at the top whenever you
change dependencies. License names reflect the common license for each package
at the time of writing and should be re-verified against the installed version._
