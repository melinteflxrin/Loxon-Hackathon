"""
Create Presentation-Ready Tables from SQL Results
Generates formatted HTML tables with styling for PowerPoint/slides
"""

import pandas as pd
from pathlib import Path

# Get absolute paths
BASE_DIR = Path(__file__).parent.parent
DATA_DIR = BASE_DIR / 'data'
OUTPUT_DIR = BASE_DIR / 'output' / 'tables'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def style_dataframe_for_presentation(df, title):
    """Apply professional styling to dataframe"""
    
    # Create HTML with custom CSS
    html = f"""
    <html>
    <head>
        <style>
            body {{
                font-family: 'Segoe UI', Arial, sans-serif;
                background: #f5f5f5;
                padding: 20px;
            }}
            h2 {{
                color: #2c3e50;
                text-align: center;
                margin-bottom: 20px;
            }}
            table {{
                border-collapse: collapse;
                width: 100%;
                background: white;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }}
            th {{
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 12px;
                text-align: left;
                font-weight: 600;
            }}
            td {{
                padding: 10px 12px;
                border-bottom: 1px solid #e0e0e0;
            }}
            tr:hover {{
                background: #f8f9fa;
            }}
            tr:nth-child(even) {{
                background: #fafafa;
            }}
            .numeric {{
                text-align: right;
                font-weight: 500;
            }}
            .highlight {{
                background: #fff3cd !important;
            }}
        </style>
    </head>
    <body>
        <h2>{title}</h2>
        {df.to_html(index=False, classes='table', border=0)}
    </body>
    </html>
    """
    
    return html

# =====================================================================
# OPTION 1: Export formatted tables for each query
# =====================================================================
def export_query_results_for_presentation():
    """
    Exports SQL results as beautifully formatted HTML tables
    Perfect for copying into PowerPoint or taking screenshots
    """
    
    queries = [
        ('query2_segment_summary.csv', 'Payment Behavior Segment Summary'),
        ('query3_quartile_analysis.csv', 'Revenue Quartile Analysis'),
        ('query4_top_customers.csv', 'Top 10 Best Customers'),
        ('query5_risky_customers.csv', 'Top 10 Risky Customers'),
        ('query6_delay_distribution.csv', 'Payment Delay Distribution'),
        ('query7_executive_summary.csv', 'Executive Summary - Key Metrics')
    ]
    
    for csv_file, title in queries:
        try:
            df = pd.read_csv(DATA_DIR / csv_file)
            
            # Format numeric columns
            for col in df.columns:
                if 'HUF' in col or 'Revenue' in col or 'Amount' in col:
                    df[col] = df[col].apply(lambda x: f'{x:,.0f}' if pd.notna(x) and isinstance(x, (int, float)) else (x if pd.notna(x) else '-'))
                elif '%' in col or 'Rate' in col:
                    df[col] = df[col].apply(lambda x: f'{x:.1f}%' if pd.notna(x) and isinstance(x, (int, float)) else (x if pd.notna(x) else '-'))
                elif 'Days' in col or 'Delay' in col:
                    df[col] = df[col].apply(lambda x: f'{x:.1f}' if pd.notna(x) and isinstance(x, (int, float)) else (x if pd.notna(x) else '-'))
            
            # Generate styled HTML
            html = style_dataframe_for_presentation(df, title)
            
            # Save file
            output_file = OUTPUT_DIR / f"{csv_file.replace('.csv', '.html')}"
            output_file.write_text(html, encoding='utf-8')
            
            print(f"✅ Created: {output_file.name}")
            
        except FileNotFoundError:
            print(f"⚠️  Skipped {csv_file} - file not found")
    
    print(f"\n✅ All tables generated in: {OUTPUT_DIR}")
    print("\n📋 How to use:")
    print("1. Open HTML files in browser")
    print("2. Take screenshot (Windows: Win+Shift+S)")
    print("3. Paste directly into PowerPoint")

if __name__ == "__main__":
    export_query_results_for_presentation()
