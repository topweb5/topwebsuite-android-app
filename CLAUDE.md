# Topwebsuite Mobile App — Engineering Guide

Rules for any change in this repository. They reflect how the codebase is
already built. Follow them exactly; if a rule blocks you, stop and ask rather
than working around it.

## Environment
- Flutter app on Dart SDK 3.9.0 (stable), Material 3, null-safe.
- Platform target includes Android (primary test device) and iOS.

## State management — Riverpod only
- All app state, dependency injection, and async data flow uses
  `flutter_riverpod`.
- Use the patterns already in the codebase:
  - `AsyncNotifierProvider` for stateful async controllers (see
    `lib/features/auth/application/auth_controller.dart`).
  - `FutureProvider` for read-only async fetches.
  - plain `Provider` for injecting clients/repositories.
  - `ConsumerWidget` / `ConsumerStatefulWidget` for widgets that read providers.
- Forbidden: BLoC/`flutter_bloc`, the `provider` package, GetX, MobX,
  Redux, `ChangeNotifier`-as-app-state, and `setState` for anything beyond
  local, ephemeral widget UI state (e.g. a password-visibility toggle).

## Architecture & layering
- Feature-first. Each feature lives in `lib/features/<feature>/` and is split
  into these layers, with dependencies pointing downward only
  (`presentation` -> `application` -> `data` -> `domain`):
  - `presentation/` — screens and feature-specific widgets.
  - `application/` — Riverpod controllers / notifiers.
  - `data/` — repositories; the only layer that talks to the API client.
  - `domain/` — plain models and config objects, no Flutter imports.
- Cross-cutting code lives in `lib/core/` (`api/`, `storage/`, `services/`,
  `utils/`, `widgets/`) and app shell in `lib/app/`
  (`app.dart`, `router.dart`, `theme.dart`, `env.dart`).
- Rules:
  - Presentation must not call the API client directly — go through a
    repository in `data/`.
  - `domain/` must not import `package:flutter/*`.
  - Networking goes through `apiClientProvider` in `lib/core/api/`. Do not
    create new Dio instances or hard-code base URLs; use `lib/app/env.dart`.
  - Routing changes go in `lib/app/router.dart` (GoRouter). Navigate with
    GoRouter (`context.go` / `context.push`), not bare `Navigator` route
    strings.

## UI: theme is the single source of truth
- Colors: use `TopwebsuiteTheme` tokens (e.g. `TopwebsuiteTheme.primary`,
  `.muted`, `.surface`, `.border`, `.danger`, `brandGradient`). No raw
  `Color(0xFF…)` or `Colors.<named>` literals in feature code. If a needed
  color is missing, add it to `TopwebsuiteTheme`, then use it.
- Text: use styles from `Theme.of(context).textTheme` (Inter). Do not write
  inline `TextStyle(...)` for new text; if a variant is missing, extend the
  theme.
- Spacing/radii: no unexplained magic numbers. Reuse the spacing and corner
  radii already used by sibling widgets; promote repeated values to named
  constants.
- Fonts come from the theme’s Inter configuration — do not set `fontFamily`
  ad hoc per widget.

## Reuse before you build
- Before creating a widget, check `lib/core/widgets/` and the feature’s
  `presentation/widgets/` (e.g. `auth_widgets.dart`) for an existing one.
  Extend or compose the existing widget rather than duplicating it.
- Shared, reusable widgets belong in `lib/core/widgets/`; widgets used by a
  single feature belong in that feature’s `presentation/widgets/`.

## Quality gate — run after every change
- Run `dart format .` and commit only formatted code.
- Run `flutter analyze` and fix every error and warning before finishing.
  Do not silence lints with `// ignore` to pass; fix the underlying issue.
- Lints follow `analysis_options.yaml` (`package:flutter_lints`). Keep it
  green.

## Testing
- Every new screen requires a matching golden test under `test/` that mirrors
  the screen’s path (e.g. `test/features/<feature>/presentation/<screen>_golden_test.dart`).
- The golden test renders the screen inside `TopwebsuiteTheme` and overrides
  any Riverpod providers it depends on with deterministic test data, so the
  golden is stable.
- Update goldens intentionally (`flutter test --update-goldens`) and review
  the image diff before committing.

## Tooling
- The Dart MCP server is registered in `.mcp.json` so the assistant can run
  and verify the app’s UI. Reload the IDE window after changing `.mcp.json`.
