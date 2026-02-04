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
    
    for post_file in posts_dir.glob('*/index.qmd'):
        try:
            content = post_file.read_text(encoding='utf-8')
            metadata = parse_frontmatter(content)
            
            slug = extract_slug(post_file)
            translation = metadata.get('translation', 'none')
            
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


if __name__ == '__main__':
    build_manifest()
