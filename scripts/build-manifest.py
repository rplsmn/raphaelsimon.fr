#!/usr/bin/env python3
"""
Build translations manifest for blog posts.
Scans en/blog/posts/ and fr/blog/posts/ directories and generates
a JSON manifest mapping slugs to language versions with translation status.
"""

import json
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Warning: PyYAML not available, using simple frontmatter parser")
    yaml = None


def parse_frontmatter(content):
    """Extract YAML frontmatter from markdown file."""
    if not content.startswith('---'):
        return {}
    
    parts = content.split('---', 2)
    if len(parts) < 3:
        return {}
    
    frontmatter_text = parts[1]
    
    if yaml:
        try:
            return yaml.safe_load(frontmatter_text) or {}
        except Exception as e:
            print(f"Warning: YAML parse error: {e}")
            return {}
    else:
        # Simple key-value parser
        metadata = {}
        for line in frontmatter_text.strip().split('\n'):
            if ':' in line:
                key, value = line.split(':', 1)
                metadata[key.strip()] = value.strip().strip('"\'')
        return metadata


def extract_slug(post_path):
    """Extract slug from post directory name."""
    # Directory name format: YYYY-MM-DD-slug or just slug
    dir_name = post_path.parent.name
    # Remove date prefix if present
    match = re.match(r'^\d{4}-\d{2}-\d{2}-(.+)$', dir_name)
    if match:
        return match.group(1)
    return dir_name


def scan_blog_posts(lang_dir):
    """Scan blog posts in a language directory."""
    posts = {}
    posts_dir = lang_dir / 'blog' / 'posts'
    
    if not posts_dir.exists():
        return posts
    
    # Read _metadata.yml defaults for this language's blog
    metadata_file = lang_dir / 'blog' / '_metadata.yml'
    default_translation = 'none'
    if metadata_file.exists():
        try:
            metadata_content = metadata_file.read_text(encoding='utf-8')
            metadata_defaults = parse_frontmatter('---\n' + metadata_content + '\n---')
            default_translation = metadata_defaults.get('translation', 'none')
        except Exception as e:
            print(f"Warning: Could not read {metadata_file}: {e}")
    
    for post_file in posts_dir.glob('*/index.qmd'):
        try:
            content = post_file.read_text(encoding='utf-8')
            metadata = parse_frontmatter(content)
            
            slug = extract_slug(post_file)
            # Use post's explicit translation field, or fall back to default from _metadata.yml
            translation = metadata.get('translation', default_translation)
            
            # Get relative path from project root
            rel_path = f"/{lang_dir.name}/blog/posts/{post_file.parent.name}/"
            
            posts[slug] = {
                'path': rel_path,
                'translation': translation
            }
        except Exception as e:
            print(f"Warning: Error processing {post_file}: {e}")
    
    return posts


def build_manifest():
    """Build translations manifest from blog posts."""
    project_root = Path(__file__).parent.parent
    
    manifest = {}
    
    # Scan English posts
    en_dir = project_root / 'en'
    en_posts = scan_blog_posts(en_dir)
    
    # Scan French posts
    fr_dir = project_root / 'fr'
    fr_posts = scan_blog_posts(fr_dir)
    
    # Merge by slug
    all_slugs = set(en_posts.keys()) | set(fr_posts.keys())
    
    for slug in sorted(all_slugs):
        manifest[slug] = {}
        
        if slug in en_posts:
            manifest[slug]['en'] = en_posts[slug]
        
        if slug in fr_posts:
            manifest[slug]['fr'] = fr_posts[slug]
    
    # Write manifest
    output_file = project_root / '_data' / 'translations-manifest.json'
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    with output_file.open('w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    
    print(f"Generated manifest with {len(manifest)} posts")
    print(f"  English: {len(en_posts)} posts")
    print(f"  French: {len(fr_posts)} posts")
    print(f"  Written to: {output_file}")
    
    return manifest


def generate_hreflang_metadata(manifest):
    """
    Generate hreflang frontmatter for blog posts based on manifest.
    Returns dict: {slug: {en: path, fr: path, ...}}
    """
    hreflang_map = {}
    
    for slug, data in manifest.items():
        hreflang_map[slug] = {}
        for lang_code in data.keys():
            hreflang_map[slug][lang_code] = f"/{lang_code}/blog/posts/{slug}/"
    
    return hreflang_map


def inject_hreflang_into_posts(hreflang_map, manifest):
    """
    Update blog post frontmatter with hreflang metadata.
    Uses pathlib for cross-platform compatibility.
    """
    project_root = Path(__file__).parent.parent
    
    for slug, hreflang_data in hreflang_map.items():
        for lang_code in hreflang_data.keys():
            # Find the actual post directory (which may have date prefix)
            posts_dir = project_root / lang_code / "blog" / "posts"
            post_dir = None
            
            # Look for directory matching slug or YYYY-MM-DD-slug pattern
            if posts_dir.exists():
                for d in posts_dir.iterdir():
                    if d.is_dir() and (d.name == slug or d.name.endswith(f"-{slug}")):
                        post_dir = d
                        break
            
            if not post_dir:
                continue
                
            post_path = post_dir / "index.qmd"
            if not post_path.exists():
                continue
            
            try:
                # Read current content
                content = post_path.read_text(encoding='utf-8')
                
                # Parse frontmatter
                if not content.startswith('---'):
                    continue
                
                parts = content.split('---', 2)
                if len(parts) < 3:
                    continue
                
                frontmatter_text = parts[1]
                body = parts[2]
                
                # Parse YAML frontmatter
                if yaml:
                    metadata = yaml.safe_load(frontmatter_text) or {}
                else:
                    # Skip if no YAML parser available
                    print(f"Warning: Cannot inject hreflang into {post_path} - YAML parser not available")
                    continue
                
                # Inject hreflang
                metadata['hreflang'] = hreflang_data
                
                # Rebuild frontmatter
                new_frontmatter = yaml.dump(metadata, default_flow_style=False, allow_unicode=True, sort_keys=False)
                new_content = f"---\n{new_frontmatter}---{body}"
                
                # Write back
                post_path.write_text(new_content, encoding='utf-8')
                
            except Exception as e:
                print(f"Warning: Error processing {post_path}: {e}")


if __name__ == '__main__':
    manifest = build_manifest()
    
    # Auto-inject hreflang into blog posts
    hreflang_map = generate_hreflang_metadata(manifest)
    inject_hreflang_into_posts(hreflang_map, manifest)
