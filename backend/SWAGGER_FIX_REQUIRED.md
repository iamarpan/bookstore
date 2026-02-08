# Swagger Documentation Fix Required

## Issue Summary

The Swagger UI at `https://bookapp-ayushyachitranshs-projects.vercel.app/api-docs` loads successfully but **displays zero API endpoints**, despite all 20 endpoints being fully functional.

## Root Cause

The Swagger configuration in `backend/src/config/swagger.ts` is not correctly resolving route file paths in the Vercel production environment.

### Current Code (Lines 152-163):

```typescript
// Helper to get routes path safely
const getRoutesPath = () => {
    try {
        if (process.env.VERCEL) {
            // On Vercel, paths might be different
            return './src/routes/*.ts';
        }
        return `${__dirname}/../routes/*.ts`;
    } catch (e) {
        return './src/routes/*.ts';
    }
};
```

**Problem:** In production, TypeScript files are compiled to JavaScript in the `dist` folder. The paths point to `.ts` files that don't exist in the production build.

## Recommended Fix

Update `backend/src/config/swagger.ts`:

```typescript
// Helper to get routes path safely
const getRoutesPath = () => {
    try {
        if (process.env.VERCEL || process.env.NODE_ENV === 'production') {
            // In production, use compiled JS files from dist
            return './dist/routes/*.js';
        }
        // In development, use TypeScript source files
        return `${__dirname}/../routes/*.ts`;
    } catch (e) {
        console.error('Error resolving routes path:', e);
        return './dist/routes/*.js';
    }
};
```

### Alternative Fix (More Robust):

```typescript
import path from 'path';

const getRoutesPath = () => {
    try {
        const isDevelopment = process.env.NODE_ENV === 'development';
        const isProduction = process.env.NODE_ENV === 'production' || process.env.VERCEL;
        
        if (isProduction) {
            // Production: use compiled JS files
            const distPath = path.join(process.cwd(), 'dist', 'routes', '*.js');
            console.log('Swagger routes path (production):', distPath);
            return distPath;
        } else {
            // Development: use TypeScript source files
            const srcPath = path.join(__dirname, '..', 'routes', '*.ts');
            console.log('Swagger routes path (development):', srcPath);
            return srcPath;
        }
    } catch (e) {
        console.error('Error resolving routes path:', e);
        // Fallback to production path
        return path.join(process.cwd(), 'dist', 'routes', '*.js');
    }
};
```

## Testing the Fix

### Local Testing:
```bash
cd backend
npm run build
NODE_ENV=production npm start
# Visit http://localhost:3000/api-docs
# Verify endpoints are visible
```

### Vercel Testing:
```bash
# After deploying the fix
curl -s https://bookapp-ayushyachitranshs-projects.vercel.app/api-docs/swagger.json | jq '.paths | keys'
# Should return array of endpoint paths, not empty object
```

## Expected Result

After the fix, `/api-docs/swagger.json` should return:

```json
{
  "paths": {
    "/auth/send-otp": { ... },
    "/auth/verify-otp": { ... },
    "/auth/refresh": { ... },
    "/users/me": { ... },
    "/books/feed": { ... },
    ...
  }
}
```

Instead of the current:

```json
{
  "paths": {}
}
```

## Impact

**Current State:**
- ❌ Swagger UI shows 0 endpoints
- ✅ All APIs are functional
- ⚠️ Mobile team cannot use interactive documentation

**After Fix:**
- ✅ Swagger UI will show all 20 endpoints
- ✅ Mobile team can test APIs interactively
- ✅ Better developer experience

## Priority

**Medium-High** - APIs are working, but documentation is critical for mobile team onboarding and testing.

## Workaround (Temporary)

Mobile team has been provided with comprehensive markdown documentation:
- [MOBILE_TEAM_HANDOVER.md](file:///Users/ayushyachitransh/.gemini/antigravity/brain/ddcccf7c-05be-4915-8cfd-33ec6f71e55d/MOBILE_TEAM_HANDOVER.md)

This allows them to proceed with integration while the Swagger issue is being fixed.

## Additional Improvements

While fixing this, consider:

1. **Add logging** to help debug path resolution:
   ```typescript
   console.log('Swagger scanning routes from:', routesPath);
   ```

2. **Verify in build script** that Swagger spec is generated correctly:
   ```json
   // package.json
   {
     "scripts": {
       "build": "prisma generate && tsc && node -e \"require('./dist/config/swagger').getSwaggerSpec()\""
     }
   }
   ```

3. **Add health check** for Swagger:
   ```typescript
   app.get('/api-docs/health', (req, res) => {
     const spec = getSwaggerSpec();
     const pathCount = Object.keys(spec.paths || {}).length;
     res.json({
       status: pathCount > 0 ? 'ok' : 'error',
       endpointsFound: pathCount,
       message: pathCount > 0 ? 'Swagger working' : 'No endpoints found'
     });
   });
   ```

## Files to Modify

1. `backend/src/config/swagger.ts` - Update `getRoutesPath()` function
2. `backend/package.json` - (Optional) Add build verification
3. `backend/src/app.ts` - (Optional) Add Swagger health check

## Deployment Steps

1. Make the code changes
2. Test locally with production build
3. Commit and push to repository
4. Deploy to Vercel
5. Verify `/api-docs` shows endpoints
6. Notify mobile team that Swagger is fixed

---

**Created:** February 8, 2026  
**Status:** Pending Fix  
**Assigned To:** Backend Team
