# Architecture, folder structure and data flow

> **Hard rules — MUST be followed, never "just this once".** Items marked 🔒 are checked by `.claude/hooks/check-swift-rules.sh` after every Edit/Write; a violation is sent back and must be fixed before continuing.

These rules apply to every screen and feature. Feature-specific facts live in `.claude/rules/features/<feature>.md` (e.g. `features/calendar.md`, the reference implementation to copy from).

🔒 Enforced: Domain imports Foundation only · Alamofire only in `Core/Networking/{Client,Interceptors,Monitoring}` · SwiftData only in `Data/`.

## Golden rules
1. **Reuse before you create.** Look for an existing type, token, helper or pattern first (list below). Never add a second network client, error type, date source, cache mechanism, color/spacing file or way of doing something that already exists.
2. **Put every file in its layer and folder** (structure below). Never create a new top-level folder; a new feature gets `Features/<Feature>/`.
3. **Follow the existing flow** (patterns below): View → ViewModel → UseCase → Domain → Repository → Network / SwiftData. Do not skip a layer (e.g. a ViewModel calling a repository or `NetworkClient`).
4. **Plan before code** for anything beyond a small fix: list the files per layer, the data flow and the test cases, get approval, then write.
5. **Small, focused files**, one main type per file, named after it.

## Folder structure
```
EverfitTest/
├─ App/
│  ├─ <App>App.swift   @main; builds the root screen from AppContainer
│  └─ DI/              AppContainer — the only composition root
├─ Core/               shared infrastructure, NO business logic
│  ├─ Constants/       app-wide values only: AppColors, AppStrings
│  ├─ DesignSystem/    AppTextStyle (+ .textStyle), AppTypography, AppSpacing, AppIcons, shared UI components
│  ├─ Networking/      APIConstants, Request/, Response/, Error/, Client/, Interceptors/, Monitoring/
│  └─ Utilities/       small generic helpers (SystemDateProvider, Calendar+MondayFirst, Color+Hex)
├─ Domain/             pure Swift — imports Foundation only
│  ├─ Entities/        business models + their rules (value types)
│  ├─ Repositories/    repository PROTOCOLS only
│  ├─ Services/        pure calculations (date math…) and service protocols (DateProvider)
│  └─ UseCases/        one file per user action: protocol + Default implementation
├─ Data/
│  ├─ Remote/          DTOs/ (Codable, mirror the API exactly), Requests/ (one APIRequest per endpoint)
│  ├─ Local/           Models/ (SwiftData @Model), SwiftDataStack (schema), SwiftDataStore (shared fetch/replaceAll/upsert)
│  ├─ Mappers/         DTO → Entity (one mapper for fresh and cached data)
│  └─ Repositories/    Default<X>Repository (implements the Domain protocol)
├─ Features/<Feature>/ = Presentation layer, one folder per screen/feature
│  ├─ Views/           SwiftUI views (+ private subviews), each with #Preview
│  ├─ ViewModels/      <Screen>ViewModel
│  ├─ Models/          UI models (<Thing>Item): ready-to-render, formatted values
│  └─ Mappers/         Entity → UI model (<Screen>PresentationMapper), status → style extensions
└─ Resources/          Assets.xcassets, Fonts/
EverfitTests/          mirrors EverfitTest: Core/, Domain/, Data/, Features/<Feature>/, Support/ (shared test doubles)
```
- `Core/Constants/` holds only values the **whole app** uses. Config of one layer lives in that layer (e.g. `APIConstants` → `Core/Networking/`). Screen-specific design metrics → a nested namespace `AppSpacing.<Feature>`.
- A UI piece used by two or more features moves to `Core/DesignSystem/`.

## Layer rules (Clean Architecture)
- Dependency rule: **Features → Domain ← Data**; all may use Core. Domain never imports SwiftUI, SwiftData, Alamofire, or references Data/Features types.
- **Business logic lives only in Domain** (entities, services, use cases): calculations, status rules, what is allowed, how odd API data is normalized. Never in ViewModels, Views or mappers.
- **UseCase**: one per user action (`Load<X>UseCase`, `Toggle<X>UseCase`…). Protocol + `Default<Name>UseCase` in the same file. Depends on repository protocols + Domain services; returns Domain types; throws only `APIError`.
- **ViewModel**: `@Observable`, MainActor. Depends on use-case **protocols** only. May sequence use-case calls for display (cache → fresh, keep rows on error) and own UI state (`isLoading`, `errorMessage`); maps entities → UI models via the feature's `Mappers/` (formatting + `AppStrings` only).
- **View**: renders UI models, forwards intents to the ViewModel. No logic, no formatting, no data access.
- **Repository protocol** (Domain) speaks Domain types. **Repository implementation** (Data) is the only place that touches network and SwiftData together. Add a separate `<X>LocalDataSource` / `<X>RemoteDataSource` only when one side grows beyond simple load/save.
- Repositories reach SwiftData only through `SwiftDataStore` (never their own `ModelContext`); a new generic operation goes there, with a test.
- **DTOs and SwiftData models never leave Data.** Map in `Data/Mappers`.
- Errors: `APIError` (Core) is the one error type across layers; no per-layer error types. UI shows `error.userMessage`; `.cancelled` is silent.
- "Now" comes from `DateProvider` (injected); never `Date()` in logic.
- Navigation: when a second screen appears, add a coordinator in `App/`; views do not create other screens' ViewModels.

## DI (`App/DI/AppContainer`)
- The only place objects are created and wired. Shared infrastructure (`NetworkClient`, `SwiftDataStore`, `DateProvider`) is `private let`, created once.
- One factory per screen: `func make<Screen>ViewModel() -> <Screen>ViewModel` building Repository → UseCases → ViewModel.
- `@main` App and full-screen `#Preview`s call the factory; nothing else creates repositories or use cases.
- Split into per-feature assemblies only when the file grows large.
- A new `@Model` must be added to `SwiftDataStack.schema`.

## Data flow patterns (reuse these for new features)
**Read — offline-first**
```
View .task / .refreshable ─▶ ViewModel.load()
 ├─ ① first load only: useCase.cached<X>() ─▶ repository.cached<X>()   (SwiftData, sync) ─▶ show
 └─ ② await useCase.fetch<X>() ─▶ repository.fetch<X>() ─▶ networkClient.send(<X>Request())
        ─▶ save raw DTOs in SwiftData ─▶ DTO.toDomain()
     success → show · .cancelled → ignore · other APIError → alert, current rows stay
```
- Cache the API response **as-is** (DTOs encoded in one `@Model` row) and map it with the same `toDomain()` as fresh data. No parallel cache model.
- `cached<X>()` returns `nil` before the first successful fetch; an unreadable/old-format payload counts as no cache.
- `fetch<X>()`: API → save → return. A failed cache write must not hide fresh data (`try?`). No cache fallback inside `fetch` (the ViewModel already shows it).
- First load with nothing to show: the screen's structure built from Domain (e.g. an empty week) with the shared `LoadingIndicator` (`Core/DesignSystem`) as an `.overlay`, driven by the ViewModel's `isLoading` (true only until the first data, cache or network). Reloads keep the current content and rely on pull-to-refresh; never show the common loading again.
- Overlapping loads (`.task` + pull-to-refresh): a load counter marks the newest `load()`; an older load that finishes later changes nothing.
- Identical data needs no manual check: `@Observable` does not notify when an `Equatable` property is set to an equal value. Keep UI models `Equatable`.

**Write — user action on local state**
```
View tap ─▶ ViewModel.<action>(id:) ─▶ <Action>UseCase.execute(…, in: currentState)
          ─▶ guard allowed (Domain rule) ─▶ repository.save<X>(…) ─▶ return updated Domain value ─▶ apply
```
- User-created state is stored in its own `@Model` keyed by the API `_id`, separate from the cached response (a fetch never wipes it); the repository merges it into every read.
- Store the full value (e.g. a `Bool`, not "marked"), so an API value can be overridden both ways.
- Local writes do not throw across layers (`try?`); only `APIError` crosses layers.
- Update the UI from the returned Domain value (copy-and-modify), not by reloading.

**Errors**: one alert per failure with `AppStrings.Errors.*`, closable; no retry button unless the design has one; pull-to-refresh retries.
