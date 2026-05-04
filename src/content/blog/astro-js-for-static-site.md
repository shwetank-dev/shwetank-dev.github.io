---
title: AstroJS For Static Site
date: 2026-05-01
description: How to use Astro JS to build a simple blog?
tags: [AstroJS, javascript, static site]
---

## What is AstroJS?

- AstroJS is a framework for building content-focused websites with lots of static pages such as blogs, docs, and marketing pages. The key idea is that all the astro code is converted to HTML files at the build time.
- Such static websites have fast load times, great for SEO, and simple deploys - they can be deployed simply from github.

## Key features of AstroJS

- **File-based routing -** files in `src/pages` automatically becomes URL without any extra config. To make nested URLs we simply define subfolders with `src/pages`
- **Modularity with Layouts and Components -** we define layouts and components and use them to make our codebase modular.

## Project Structure

- The [AstroJS docs](https://docs.astro.build/en/concepts/why-astro/) are very well written.
- This blog is build in Astro using the following project structure.

```
my-blog/
├── src/
│   ├── pages/                    # file-based routes → URLs
│   │   ├── index.astro           # → /
│   │   ├── about.astro           # → /about
│   │   ├── blog/
│   │   │   └── [slug].astro      # → /blog/any-post
│   │   └── tags/
│   │       ├── index.astro       # → /tags
│   │       └── [tag].astro       # → /tags/any-tag
│   ├── layouts/                  # page shell templates
│   │   ├── BaseLayout.astro      # header, nav, footer wrapper
│   │   └── BlogPostLayout.astro  # post metadata + content
│   ├── components/               # reusable UI pieces
│   │   ├── Nav.astro
│   │   └── TagList.astro
│   ├── content/
│   │   ├── blog/                 # markdown posts live here
│   │   │   └── hello-world.md
│   │   └── config.ts             # schema + frontmatter validation
│   └── styles/
│       └── global.css            # css reset + custom properties
├── public/                       # static assets, served as-is
│   └── favicon.ico
├── astro.config.mjs              # site, base, integrations
└── package.json
```

## `.astro` files

- Astro files are used to define UI components, pages and layouts. They have a JS frontmatter and HTML-like template.
- The JS in the frontmatter runs on the server at the build time.
- Variables declared in the frontmatter are available inside HTML template.
- They can use components.

## `.md` files

- `.md` files represent the written content.
- They have YAML like frontmatter. The frontmatter must follow the schema defined as per the collection.

## Collection

- A collection in AstroJS is a folder of Markdown files with validated schema. For eg in this project `src/content/blog/` is the folder.
- We define the schema is `src/content.config.ts` using `zod`
- This schema is used to validate the frontmatter of each entry (ie `.md`) file inside the collection. If there is some error in frontmatter, then the build fails.
- We can think of this as a 'database' of our markdown content.

## `getCollection`

- `getCollection` is a function from `astro:content` that reads all the `.md` files in a collection and returns them as an array at build time.
- You can think that this how we fetch data from database. It returns `Array{ id, data, body, filePath, rendered, collection }` where
  - `id`: filename without extension (eg `foo`)
  - `data`: the validated frontmatter object
  - `body`: raw Markdwon String
  - `filePath`: full filepath
  - `digest`: for internal optimization. Internal implementation detail.
  - `rendered`: pre-rendered HTML output. Internal implementation detail.
  - `collection`: collection name ie `blog`

- For eg we fetch all blogs by `const allBlogs = await getCollection('blog')`. Then we sort them by date and and pass individual blogs information to `BlogCard` component to display these in the homepage.

## Component

- A component is an `.astro` file at `src/components/` which represent a reusable piece of UI which we define once and use everywhre.

- A component gets props via `Astro.props` which are destructured in the Component frontmatter. We can declare types for props by declaring `interface Props {}`. (`Props` is a special keyword to give types to the props)

- Components can call subcomponents. For eg in the `BlogCard` component we are calling the `Taglist` component.

- Note that in the `BlogCard` component we use `a[href="/blog/:slug"]` because `slug` prop refers to the filename. Astro.js uses "file based routing" to automatically show the content of the relevant page.

## File Based Routing

- File based routing in Astro ensures that the URLs of the HTML pages are derived automatically from `src/pages`. For eg `src/pages/index.astro` would become the homepage of the website.

- We define dynamic routes by using `[slug]` in the filepath `src/pages/blog/[slug].astro` would becomes `/blog/slug` in the website where the value of the `[slug]` will be provided dynamically.

## How does Astro determine value inside `[slug]` in dynamic routes?

- Dynamic pages with `[slug]` will generate multiple HTML files, corresponding to different values of the `slug`.

- For this the front matter of the dynamic page needs to export `async function getStaticPaths()`. If this function is not provided, then Astro throws an error.

- At build time, Astro does the following:
  1. Scans `src/pages/` for files with `[slug]` in the name
  2. Calls `getStaticPaths()` on each one
  3. The function returns `Array<{ params: { ... }, props: { ... }}>`
  4. Renders the `.astro` file once per entry, injecting the matching `params` and `props` each time.
    - The `params` only exists to tell Astro what filename to generate. The keys are typically placeholders like `slug`
    - The `props` refer to the data passed inside this file.
  5. Writes one HTML file per render to `dist/`

- The `props` for each entry generated by `getStaticPaths` is received by `Astro.props` and destructured in the same frontmatter like any other `.astro` file.

- `await render(CollectionItem)` takes the collection entry and converts its Markdown into HTML. It returns, among other things, a `Content` object which we place in the HTML template by `<Content />` which returns the whole HTML body.

## How do we pass values to `.astro` files.

- For a child component, we can only pass values as a parent component via `props` which is available in the frontmatter using `Astro.props`
- A dynamic page like `[slug].astro` can not be used as a child component. It gets values from `getStaticPaths` via `props` on the same file. As discussed earlier, this function returns `Array<{params: {}, props {}}>`.