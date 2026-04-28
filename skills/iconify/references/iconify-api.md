# Iconify API Notes

Source: <https://iconify.design/docs/api/>

## Public API

Base URL: `https://api.iconify.design`

Iconify hosts a public API for icon data, SVG generation, CSS generation, collections, and search. The public API can be self-hosted if reliability, privacy, or custom icon sets require it.

## Search

Source: <https://iconify.design/docs/api/search.html>

Endpoint: `/search`

Required query parameter:

- `query`: case-insensitive search text.

Useful optional parameters:

- `limit`: result count. API minimum is 32, default is 64, maximum is 999.
- `start`: pagination start index.
- `prefix`: restrict to one icon set.
- `prefixes`: comma-separated icon set prefixes. Partial prefixes ending in `-` are allowed.
- `category`: restrict to a collection category.

Response includes:

- `icons`: full icon ids such as `mdi-light:home`.
- `collections`: metadata keyed by prefix, including name, license, author, category, and `palette`.

## SVG Rendering

Source: <https://iconify.design/docs/api/svg.html>

Endpoint: `/{prefix}/{name}.svg`

Useful optional parameters:

- `color`: replaces `currentColor` with a hard-coded color. Hex colors must encode `#` as `%23`.
- `width`, `height`: set dimensions. `auto` uses viewBox values; `unset` or `none` removes dimensions.
- `flip`: `horizontal`, `vertical`, or both separated by comma.
- `rotate`: `90deg`, `180deg`, `270deg`, or `1`, `2`, `3`.
- `box=1`: adds a transparent rectangle matching the viewBox.

For inline SVG files in codebases, omit `color` so monotone icons stay themeable via `currentColor`.

## Icon Data

Source: <https://iconify.design/docs/api/icon-data.html>

Endpoint: `/{prefix}.json?icons={name1,name2}`

Use one prefix per request. Missing icons are returned in `not_found`. Sort icon names in repeated requests for better cache behavior.

## Collections

Sources:

- <https://iconify.design/docs/api/collections.html>
- <https://iconify.design/docs/api/collection.html>

Endpoints:

- `/collections`: list icon sets and metadata.
- `/collection?prefix={prefix}`: list icons in one icon set.
