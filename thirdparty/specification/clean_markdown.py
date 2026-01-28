#!/usr/bin/env python3
"""Clean up markdown files converted from AsciiDoc via HTML."""

import re
import glob
import sys

def clean_markdown(content):
    """Clean up HTML-like formatting from converted markdown."""
    lines = content.split('\n')
    cleaned_lines = []
    skip_next_empty = False
    in_table_artifact = False
    
    i = 0
    while i < len(lines):
        line = lines[i]
        original_line = line
        
        # Skip lines that are just colons or HTML div markers
        if re.match(r'^:+[^:]*$', line) or re.match(r'^:::$', line) or re.match(r'^:+$', line):
            skip_next_empty = True
            i += 1
            continue
        
        # Remove HTML-style attributes from headers and links
        line = re.sub(r'\{#[^}]+\}', '', line)
        line = re.sub(r'\{[^}]*style="[^"]*"[^}]*\}', '', line)
        line = re.sub(r'\{[^}]*class="[^"]*"[^}]*\}', '', line)
        line = re.sub(r'\{[^}]*id="[^"]*"[^}]*\}', '', line)
        line = re.sub(r'\{[^}]*\}', '', line)
        
        # Remove HTML paragraph markers
        if line.strip() == '::: paragraph' or line.strip() == ':::' or line.strip().startswith('::: '):
            skip_next_empty = True
            i += 1
            continue
        
        # Remove section markers
        if re.match(r'^:+ sectionbody$', line) or re.match(r'^:+ sect\d+$', line):
            skip_next_empty = True
            i += 1
            continue
        
        # Handle table formatting artifacts (ASCII art tables from note blocks)
        if re.match(r'^\+\-+\+$', line):
            # Look ahead to see if this is a note block table
            j = i + 1
            note_text = None
            while j < len(lines) and j < i + 10:
                if 'Note' in lines[j] and 'paragraph' in lines[j]:
                    # Try to extract the note text
                    for k in range(j, min(j + 5, len(lines))):
                        if 'Khronos posts' in lines[k] or 'Registry' in lines[k]:
                            note_text = re.sub(r'^.*\|.*\|', '', lines[k]).strip()
                            note_text = re.sub(r':::', '', note_text).strip()
                            note_text = re.sub(r'paragraph', '', note_text).strip()
                            if note_text:
                                break
                    break
                j += 1
            
            if note_text:
                # Convert to markdown note block
                cleaned_lines.append('')
                cleaned_lines.append('> **Note**')
                cleaned_lines.append('> ' + note_text)
                cleaned_lines.append('')
                # Skip the entire table
                while i < len(lines) and not re.match(r'^\+\-+\+$', lines[i]):
                    i += 1
                i += 1  # Skip the closing table line
                continue
            else:
                # Just a regular table artifact, skip it
                in_table_artifact = True
                skip_next_empty = True
                i += 1
                continue
        
        if in_table_artifact:
            # Skip table rows that are just formatting
            if re.match(r'^\|.*\|$', line) and (':::' in line or 'title' in line.lower() or 'paragraph' in line.lower() or not line.strip('|').strip()):
                i += 1
                continue
            # End of table artifact
            if re.match(r'^\+\-+\+$', line):
                in_table_artifact = False
                skip_next_empty = True
                i += 1
                continue
        
        # Remove trailing backslashes from author lines
        line = line.rstrip('\\')
        
        # Clean up special characters in headers
        line = line.replace('^™^', '™')
        line = line.replace('^®^', '®')
        
        # Clean up empty author line markers
        if line.strip() == '[The Khronos® 3D Formats Working Group]' and i < len(lines) - 1:
            next_line = lines[i + 1] if i + 1 < len(lines) else ''
            if next_line.strip() == 'Table of Contents':
                skip_next_empty = True
                i += 1
                continue
        
        # Skip empty lines after removed content
        if skip_next_empty and not line.strip():
            skip_next_empty = False
            i += 1
            continue
        
        skip_next_empty = False
        in_table_artifact = False
        
        # Add proper spacing before headers
        if line.startswith('##') and cleaned_lines and cleaned_lines[-1].strip():
            cleaned_lines.append('')
        
        cleaned_lines.append(line)
        i += 1
    
    # Join and clean up multiple blank lines
    content = '\n'.join(cleaned_lines)
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    # Add proper spacing between paragraphs (where sentences run together)
    # This is a simple heuristic - add blank line after sentence-ending punctuation
    # but only if the next line starts with a capital letter
    lines = content.split('\n')
    fixed_lines = []
    for i, line in enumerate(lines):
        fixed_lines.append(line)
        # If line ends with sentence punctuation and next line starts with capital, add blank
        if (i < len(lines) - 1 and 
            re.search(r'[.!?]$', line.rstrip()) and 
            lines[i + 1] and 
            re.match(r'^[A-Z]', lines[i + 1].lstrip())):
            fixed_lines.append('')
    
    content = '\n'.join(fixed_lines)
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    # Remove leading/trailing whitespace
    content = content.strip()
    
    return content + '\n'

def main():
    """Process all markdown files except README."""
    md_files = [f for f in glob.glob('*.md') if f != 'README.md']
    
    if not md_files:
        print("No markdown files found to clean")
        return
    
    for md_file in sorted(md_files):
        print(f"Cleaning {md_file}...")
        try:
            with open(md_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            cleaned = clean_markdown(content)
            
            with open(md_file, 'w', encoding='utf-8') as f:
                f.write(cleaned)
            
            print(f"  ✓ Cleaned {md_file}")
        except Exception as e:
            print(f"  ✗ Error cleaning {md_file}: {e}")
            sys.exit(1)
    
    print(f"\nAll {len(md_files)} files cleaned successfully")

if __name__ == '__main__':
    main()

