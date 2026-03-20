-- ==========================================================
-- RandomGreeting v2 - Locale Setup
-- Creates the global tables that locale files write into.
-- Loaded BEFORE the actual locale files.
-- ==========================================================

-- RG_L              : Active UI strings (populated by ApplyLocale at runtime)
-- RG_DEFAULTS       : Active default message lists (populated by ApplyLocale)
-- RG_LOCALES        : All locale strings, keyed by locale code
-- RG_LOCALE_DEFAULTS: All default message lists, keyed by locale code
-- RG_Internal       : Shared function table for cross-file access
RG_L = {}
RG_DEFAULTS = {
    hi  = {},
    bye = {},
}
RG_LOCALES         = {}
RG_LOCALE_DEFAULTS = {}
RG_Internal        = {}
