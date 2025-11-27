"""
Creates a comparison table showing SQL vs AI capabilities
Perfect for transitioning between SQL results and AI dashboard in presentation
"""

import plotly.graph_objects as go
from pathlib import Path

# Get absolute paths
BASE_DIR = Path(__file__).parent.parent
OUTPUT_DIR = BASE_DIR / 'output'
OUTPUT_DIR.mkdir(exist_ok=True)

def create_sql_vs_ai_comparison():
    """Creates a visual comparison table of SQL vs AI capabilities"""
    
    fig = go.Figure(data=[go.Table(
        columnwidth=[180, 300, 300],
        header=dict(
            values=['<b>Feature</b>', '<b>SQL Reports</b>', '<b>AI Models</b>'],
            fill_color='#667eea',
            align='left',
            font=dict(color='white', size=14, family='Arial Black'),
            height=40
        ),
        cells=dict(
            values=[
                # Feature column
                [
                    '<b>📊 Data</b>',
                    '<b>💡 What It Does</b>',
                    '<b>🎯 Segmentation</b>',
                    '<b>🤖 Prediction</b>',
                    '<b>⚡ Fraud Detection</b>'
                ],
                # SQL column
                [
                    '<b>278 customers</b> with orders',
                    'Shows what happened in the past',
                    '5 groups by payment timing',
                    '❌ No predictions',
                    '❌ No automation'
                ],
                # AI column
                [
                    '<b>66 customers</b> with complete history',
                    'Predicts what will happen next',
                    '4 groups by behavior patterns',
                    '✅ 92.86% accuracy',
                    '✅ Found 11 suspicious transactions'
                ]
            ],
            fill_color=[
                ['#f8f9fa', '#ffffff', '#f8f9fa', '#ffffff', '#f8f9fa', '#ffffff', '#f8f9fa', '#ffffff', '#f8f9fa'],
                ['#e3f2fd'] * 9,  # Light blue for SQL
                ['#e8f5e9'] * 9   # Light green for AI
            ],
            align='left',
            font=dict(size=12),
            height=60
        )
    )])
    
    fig.update_layout(
        title={
            'text': '<b>SQL vs AI Approach</b>',
            'x': 0.5,
            'xanchor': 'center',
            'font': {'size': 24, 'color': '#2c3e50'}
        },
        height=550,
        margin=dict(l=20, r=20, t=80, b=120)
    )
    
    # Add explanation below
    fig.add_annotation(
        text="<b>Bottom Line:</b><br>" +
             "SQL = Full business picture (all 278 customers with orders, even unpaid ones)<br>" +
             "AI = Deep dive on actual paying customers (66 with complete payment behavior to learn from)",
        xref="paper", yref="paper",
        x=0.5, y=-0.15,
        showarrow=False,
        font=dict(size=13),
        align="center",
        xanchor="center",
        yanchor="top",
        bordercolor="#c7c7c7",
        borderwidth=2,
        borderpad=12,
        bgcolor="#fffbf0"
    )
    
    fig.write_html(OUTPUT_DIR / 'sql_vs_ai_comparison.html')
    print("✅ SQL vs AI comparison table saved: output/sql_vs_ai_comparison.html")
    return fig

if __name__ == "__main__":
    print("📊 Creating SQL vs AI Comparison Table...\n")
    create_sql_vs_ai_comparison()
    print("\n✅ Comparison table generated!")
    print("📁 Open: output/sql_vs_ai_comparison.html")
    print("\n🎤 Use this slide to transition from SQL results to AI dashboard in your presentation")
