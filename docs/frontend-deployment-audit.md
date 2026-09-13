# Frontend deployment audit

## Source audited

Archive: `mama-salama-frontend-main.zip`

Commit identifier embedded in the archive: `dbba5aa09ed8c5f88bbb9344c38b37b65c1fce36`

## Result

The frontend is compatible with Azure Static Web Apps.

- Framework: React 19 + TypeScript
- Build tool: Vite 8
- Package manager: npm
- Install command: `npm ci`
- Validation command: `npm run lint`
- Build command: `npm run build`
- Build output directory: `dist`
- API base URL: `/api/core`
- Local development proxy: `http://localhost:8080`
- Production API endpoint is not hard-coded.

The existing frontend API code does not need to be changed when Azure Static Web Apps is linked to the public Container App gateway through the `/api` prefix.

## Verification performed

```bash
npm ci
npm run lint
npm run build
```

The production build completed successfully. Lint completed with two non-blocking React Fast Refresh warnings in:

- `src/context/AuthContext.tsx`
- `src/context/UILanguageContext.tsx`

Vite also reported a non-blocking bundle-size warning because the main JavaScript bundle is larger than 500 kB. This does not block the PFE deployment.

## Required Static Web Apps configuration

The frontend repository should contain `staticwebapp.config.json` so client-side React Router URLs fall back to `index.html`:

```json
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/api/*", "/*.{css,js,png,jpg,jpeg,gif,svg,ico,json}"]
  }
}
```

This file belongs in the frontend repository's `public/` directory so Vite copies it to `dist/`.

## Azure integration

The final request path remains unchanged:

```text
Browser /api/core/*
  -> Azure Static Web Apps
  -> linked Container App gateway
  -> service-gateway
  -> mama-salama-core
```

The Static Web App must use the Standard plan for the linked Container Apps backend.

## Remaining dependency

Do not activate the frontend infrastructure yet. First deploy and validate the public gateway Container App, then add the linked backend resource and deploy the frontend.
