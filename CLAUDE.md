# LLM Instructions for raphaelsimon.fr

## Project Overview
Personal website for Raphaël Simon hosted at raphaelsimon.fr. Static site for blogging and consulting services.

## Core Principles
- **Simplicity first**: No fancy portfolios, shops, or complex modules
- **Static only**: No backend servers (WASM is fine)
- **Easy maintenance**: Site should not be a burden to maintain
- **Markdown-centric**: Blog posts are .md files that can be written anywhere, even on a phone

## What Is Welcome
- Dark/light theme with dark default
- Advanced search (ctrl+k style like duckdb.org)
- Contact forms (using static form services)
- Category systems for blog organization
- Navigation aids (backlinks, breadcrumbs)
- Social links integration
- Latest posts on homepage
- WASM for effects/enhancements
- Automated builds from markdown
- Multilingual content (FR/EN primarily, also IT/ES/DE)

## What Is Superfluous
- Backend servers or databases
- Complex portfolio systems
- E-commerce functionality
- Authentication/user systems
- Content management dashboards
- Heavy JavaScript frameworks if simpler options exist

## Focus Areas
1. **Content workflow**: Optimize for quick markdown → published flow
2. **Search functionality**: Implement robust site search with keyboard shortcuts
3. **Navigation**: Clear paths from any page to home/blog/contact/socials
4. **Theme**: Professional dark theme as default
5. **Static generation**: Use proven static site generators (Hugo, Quarto, etc.)

## Technical Constraints
- Must work with standard Git workflows
- Should be deployable as static files
- Minimize build complexity
- Optimize for LLM contributions (clear structure, consistent patterns)

## Content Context
Blog topics vary widely: medicine, public health, software engineering, data science, policy, complex systems. Consulting offering targets niche/complex interdisciplinary problems.

## When Making Changes
- Keep it simple and maintainable
- Preserve markdown-first workflow
- Test that changes don't break static generation
- Ensure dark theme remains default
- Verify navigation remains clear
