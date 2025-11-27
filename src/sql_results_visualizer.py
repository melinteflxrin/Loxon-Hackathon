"""
SQL Results Visualizer for Payment Behavior Segmentation
"""

import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
from pathlib import Path

# Get absolute paths
BASE_DIR = Path(__file__).parent.parent
DATA_DIR = BASE_DIR / 'data'
OUTPUT_DIR = BASE_DIR / 'output'
OUTPUT_DIR.mkdir(exist_ok=True)

# =====================================================================
# STEP 1: Export SQL Results to CSV
# =====================================================================
# In SQL Developer:
# 1. Run each query from 04b_customer_payment_behavior_queries.sql
# 2. Right-click results → Export → CSV
# 3. Save files as:
#    - query1_customer_behavior.csv
#    - query2_segment_summary.csv
#    - query3_quartile_analysis.csv
#    - query4_top_customers.csv
#    - query5_risky_customers.csv
#    - query6_delay_distribution.csv
#    - query7_executive_summary.csv

# =====================================================================
# VISUALIZATION 1: Payment Behavior Segment Distribution
# =====================================================================
def visualize_segment_summary():
    """Creates pie chart and bar chart for segment distribution"""
    # Load data
    df = pd.read_csv(DATA_DIR / 'query2_segment_summary.csv')
    
    # Create subplots
    fig = make_subplots(
        rows=1, cols=2,
        subplot_titles=('Customer Distribution', 'Revenue by Segment'),
        specs=[[{"type": "pie"}, {"type": "bar"}]]
    )
    
    # Pie chart - Customer count
    fig.add_trace(
        go.Pie(
            labels=df['Payment Behavior Segment'],
            values=df['# Customers'],
            hole=0.4,
            marker=dict(colors=['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7'])
        ),
        row=1, col=1
    )
    
    # Bar chart - Revenue
    fig.add_trace(
        go.Bar(
            x=df['Payment Behavior Segment'],
            y=df['Total Revenue (HUF)'],
            marker=dict(color='#45B7D1'),
            text=df['Total Revenue (HUF)'].apply(lambda x: f'{x:,.0f}'),
            textposition='outside'
        ),
        row=1, col=2
    )
    
    fig.update_layout(
        title_text="Payment Behavior Segmentation Analysis",
        height=800,
        showlegend=True,
        margin=dict(b=300)
    )
    
    # Add text annotation below the chart
    fig.add_annotation(
        text="<b>What This Shows:</b><br>" +
             "• Left chart: How many customers are in each payment group<br>" +
             "• Right chart: How much money each group brings in<br><br>" +
             "<b>Key Points:</b><br>" +
             "• Most customers (88%) never paid anything<br>" +
             "• Late payers are only 3.6% of customers but bring in lots of money<br>" +
             "• These late payers need special attention, not just automatic reminders",
        xref="paper", yref="paper",
        x=0.5, y=-0.32,
        showarrow=False,
        font=dict(size=11),
        align="left",
        xanchor="center",
        yanchor="top",
        bordercolor="#c7c7c7",
        borderwidth=1,
        borderpad=10,
        bgcolor="#f9f9f9"
    )
    
    fig.write_html(OUTPUT_DIR / 'segment_distribution.html')
    print("✅ Segment distribution chart saved: output/segment_distribution.html")
    return fig

# =====================================================================
# VISUALIZATION 2: Revenue Quartile Analysis
# =====================================================================
def visualize_quartile_analysis():
    """Creates stacked visualization of quartile performance"""
    df = pd.read_csv(DATA_DIR / 'query3_quartile_analysis.csv')
    
    fig = make_subplots(
        rows=2, cols=1,
        subplot_titles=('Revenue Distribution by Quartile', 'Payment Delay by Quartile'),
        vertical_spacing=0.15
    )
    
    # Revenue bars
    fig.add_trace(
        go.Bar(
            x=df['Quartile Description'],
            y=df['Total Revenue (HUF)'],
            name='Total Revenue',
            marker=dict(color=['#96CEB4', '#FFEAA7', '#FF6B6B', '#4ECDC4']),
            text=df['Total Revenue (HUF)'].apply(lambda x: f'{x:,.0f}' if pd.notna(x) else '0'),
            textposition='outside'
        ),
        row=1, col=1
    )
    
    # Delay line chart
    fig.add_trace(
        go.Scatter(
            x=df['Quartile Description'],
            y=df['Avg Payment Delay (Days)'],
            mode='lines+markers+text',
            name='Avg Delay',
            marker=dict(size=12, color='#E74C3C'),
            line=dict(width=3),
            text=df['Avg Payment Delay (Days)'].apply(lambda x: f'{x:.1f}d' if pd.notna(x) else 'N/A'),
            textposition='top center'
        ),
        row=2, col=1
    )
    
    fig.update_xaxes(title_text="Quartile", row=2, col=1)
    fig.update_yaxes(title_text="Revenue (HUF)", row=1, col=1)
    fig.update_yaxes(title_text="Days", row=2, col=1)
    
    fig.update_layout(
        title_text="Revenue Quartile Performance",
        height=1100,
        showlegend=False,
        margin=dict(b=280)
    )
    
    # Add text annotation below the chart
    fig.add_annotation(
        text="<b>What This Shows:</b><br>" +
             "• Customers split into 4 groups by how much they spend (Q1=lowest to Q4=highest)<br>" +
             "• Top chart: Total money from each group<br>" +
             "• Bottom chart: How late each group pays<br><br>" +
             "<b>Key Points:</b><br>" +
             "• Big spenders (Q3, Q4) take longer to pay<br>" +
             "• They might be using our money while they wait to pay<br>" +
             "• Can't treat high-value customers the same as low-value ones",
        xref="paper", yref="paper",
        x=0.5, y=-0.22,
        showarrow=False,
        font=dict(size=11),
        align="left",
        xanchor="center",
        yanchor="top",
        bordercolor="#c7c7c7",
        borderwidth=1,
        borderpad=10,
        bgcolor="#f9f9f9"
    )
    
    fig.write_html(OUTPUT_DIR / 'quartile_analysis.html')
    print("✅ Quartile analysis chart saved: output/quartile_analysis.html")
    return fig

# =====================================================================
# VISUALIZATION 3: Top vs Risky Customers Comparison
# =====================================================================
def visualize_customer_comparison():
    """Shows top 10 best vs top 10 risky customers"""
    top = pd.read_csv(DATA_DIR / 'query4_top_customers.csv')
    risky = pd.read_csv(DATA_DIR / 'query5_risky_customers.csv')
    
    fig = make_subplots(
        rows=1, cols=2,
        subplot_titles=('Top 10 Best Customers', 'Top 10 Risky Customers')
    )
    
    # Top customers
    fig.add_trace(
        go.Bar(
            y=top['Customer Name'][::-1],  # Reverse for top-down display
            x=top['Total Revenue (HUF)'][::-1],
            orientation='h',
            marker=dict(color='#2ECC71'),
            text=top['Total Revenue (HUF)'][::-1].apply(lambda x: f'{x:,.0f}'),
            textposition='outside',
            name='Best'
        ),
        row=1, col=1
    )
    
    # Risky customers
    fig.add_trace(
        go.Bar(
            y=risky['Customer Name'][::-1],
            x=risky['Avg Payment Delay (Days)'][::-1],
            orientation='h',
            marker=dict(color='#E74C3C'),
            text=risky['Avg Payment Delay (Days)'][::-1].apply(lambda x: f'{x:.0f}d' if pd.notna(x) else 'N/A'),
            textposition='outside',
            name='Risky'
        ),
        row=1, col=2
    )
    
    fig.update_xaxes(title_text="Revenue (HUF)", row=1, col=1)
    fig.update_xaxes(title_text="Delay (Days)", row=1, col=2)
    
    fig.update_layout(
        title_text="Customer Segmentation: Best vs Risky",
        height=900,
        showlegend=False,
        margin=dict(b=320)
    )
    
    # Add text annotation below the chart
    fig.add_annotation(
        text="<b>What This Shows:</b><br>" +
             "• Left side: Our 10 best customers (high money + pay well)<br>" +
             "• Right side: Our 10 worst customers (long delays)<br><br>" +
             "<b>Key Points:</b><br>" +
             "• Best customers should get rewards and special treatment<br>" +
             "• Worst customers delay 1,000+ days (almost 3 years!)<br>" +
             "• Risky ones need immediate action: payment plans or collections<br>" +
             "• Two different strategies needed: keep good ones happy, fix bad ones",
        xref="paper", yref="paper",
        x=0.5, y=-0.30,
        showarrow=False,
        font=dict(size=11),
        align="left",
        xanchor="center",
        yanchor="top",
        bordercolor="#c7c7c7",
        borderwidth=1,
        borderpad=10,
        bgcolor="#f9f9f9"
    )
    
    fig.write_html(OUTPUT_DIR / 'customer_comparison.html')
    print("✅ Customer comparison chart saved: output/customer_comparison.html")
    return fig

# =====================================================================
# VISUALIZATION 4: Payment Delay Distribution (Histogram)
# =====================================================================
def visualize_delay_distribution():
    """Creates histogram of payment delays"""
    df = pd.read_csv(DATA_DIR / 'query6_delay_distribution.csv')
    
    fig = go.Figure()
    
    fig.add_trace(
        go.Bar(
            x=df['Payment Delay Range'],
            y=df['# Payments'],
            marker=dict(
                color=df['% of Payments'],
                colorscale='RdYlGn_r',  # Red (bad) to Green (good)
                showscale=True,
                colorbar=dict(title="% of Payments")
            ),
            text=df.apply(lambda row: f"{row['# Payments']}<br>({row['% of Payments']}%)", axis=1),
            textposition='outside'
        )
    )
    
    fig.update_layout(
        title="Payment Delay Distribution - Time to Payment Analysis",
        xaxis_title="Delay Range",
        yaxis_title="Number of Payments",
        height=850,
        margin=dict(b=320)
    )
    
    # Add text annotation below the chart
    fig.add_annotation(
        text="<b>What This Shows:</b><br>" +
             "• How long it takes customers to pay after ordering<br>" +
             "• Each bar = number of payments in that time range<br>" +
             "• Colors show percentage of total payments<br><br>" +
             "<b>Key Points:</b><br>" +
             "• Some pay early (before they need to) - good sign<br>" +
             "• Many take over 1 year to pay - big problem<br>" +
             "• This shows when to send reminders (after 30 days? 60 days?)<br>" +
             "• Helps set realistic payment deadlines",
        xref="paper", yref="paper",
        x=0.5, y=-0.32,
        showarrow=False,
        font=dict(size=11),
        align="left",
        xanchor="center",
        yanchor="top",
        bordercolor="#c7c7c7",
        borderwidth=1,
        borderpad=10,
        bgcolor="#f9f9f9"
    )
    
    fig.write_html(OUTPUT_DIR / 'delay_distribution.html')
    print("✅ Delay distribution chart saved: output/delay_distribution.html")
    return fig

# =====================================================================
# VISUALIZATION 5: Executive Dashboard (KPI Cards)
# =====================================================================
def visualize_executive_summary():
    """Creates executive dashboard with key metrics"""
    df = pd.read_csv(DATA_DIR / 'query7_executive_summary.csv')
    
    # Extract metrics
    metrics = {
        'Total Customers': df['Total Customers'].iloc[0],
        'Total Orders': df['Total Orders'].iloc[0],
        'Total Payments': df['Total Payments'].iloc[0],
        'Payment Rate': df['Overall Payment Rate %'].iloc[0],
        'Collection Rate': df['Collection Rate %'].iloc[0],
        'Avg Delay': df['Avg Payment Delay (Days)'].iloc[0],
        'Late Payment Rate': df['Late Payment Rate %'].iloc[0],
        'Total Revenue': df['Total Orders Value (HUF)'].iloc[0],
        'Total Collected': df['Total Collected (HUF)'].iloc[0]
    }
    
    # Create KPI cards
    fig = make_subplots(
        rows=3, cols=3,
        subplot_titles=(
            f"Total Customers<br><b>{metrics['Total Customers']}</b>",
            f"Payment Rate<br><b>{metrics['Payment Rate']:.1f}%</b>",
            f"Collection Rate<br><b>{metrics['Collection Rate']:.1f}%</b>",
            f"Total Revenue<br><b>{metrics['Total Revenue']:,.0f} HUF</b>",
            f"Total Collected<br><b>{metrics['Total Collected']:,.0f} HUF</b>",
            f"Avg Delay<br><b>{metrics['Avg Delay']:.1f} days</b>",
            f"Total Orders<br><b>{metrics['Total Orders']}</b>",
            f"Total Payments<br><b>{metrics['Total Payments']}</b>",
            f"Late Rate<br><b>{metrics['Late Payment Rate']:.1f}%</b>"
        ),
        specs=[[{"type": "indicator"}, {"type": "indicator"}, {"type": "indicator"}],
               [{"type": "indicator"}, {"type": "indicator"}, {"type": "indicator"}],
               [{"type": "indicator"}, {"type": "indicator"}, {"type": "indicator"}]]
    )
    
    # Add indicators (color-coded)
    colors = ['#3498db', '#2ecc71', '#2ecc71', '#9b59b6', '#9b59b6', '#e74c3c', '#3498db', '#3498db', '#e74c3c']
    
    for i in range(3):
        for j in range(3):
            idx = i * 3 + j
            fig.add_trace(
                go.Indicator(
                    mode="number",
                    value=list(metrics.values())[idx] if isinstance(list(metrics.values())[idx], (int, float)) else 0,
                    number={'font': {'size': 1, 'color': colors[idx]}}  # Hidden, title shows value
                ),
                row=i+1, col=j+1
            )
    
    fig.update_layout(
        title_text="Executive Summary - Payment Performance KPIs",
        height=950,
        font=dict(size=14),
        margin=dict(b=340)
    )
    
    # Add text annotation below the chart
    fig.add_annotation(
        text="<b>What This Shows:</b><br>" +
             "• Top-level numbers from our entire customer database<br>" +
             "• All the important stats in one view<br><br>" +
             "<b>Key Points:</b><br>" +
             "• We collect 99% of money eventually (good)<br>" +
             "• But it takes 235 days on average (7+ months!) - bad<br>" +
             "• Only 57% of orders ever get paid<br>" +
             "• 33% of customers who pay are late<br>" +
             "• Bottom line: Money is stuck for too long = cash flow problems<br>" +
             "• We need better systems to get paid faster",
        xref="paper", yref="paper",
        x=0.5, y=-0.30,
        showarrow=False,
        font=dict(size=11),
        align="left",
        xanchor="center",
        yanchor="top",
        bordercolor="#c7c7c7",
        borderwidth=1,
        borderpad=10,
        bgcolor="#f9f9f9"
    )
    
    fig.write_html(OUTPUT_DIR / 'executive_summary.html')
    print("✅ Executive summary dashboard saved: output/executive_summary.html")
    return fig

# =====================================================================
# MAIN: Generate All Visualizations
# =====================================================================
def generate_all_visualizations():
    """Generates all presentation charts"""
    print("Generating SQL Results Visualizations...\n")
    
    try:
        visualize_segment_summary()
        visualize_quartile_analysis()
        visualize_customer_comparison()
        visualize_delay_distribution()
        visualize_executive_summary()
        
        print("\nAll visualizations generated successfully!")
        print("Output files saved in: output/")
        print("\nFor presentation:")
        print("   1. Open HTML files in browser")
        print("   2. Present in fullscreen mode")
        print("   3. Interactive charts allow zooming/hovering")
        
    except FileNotFoundError as e:
        print(f"\nError: {e}")
        print("\nTo use this script:")
        print("1. Run queries from 04b_customer_payment_behavior_queries.sql")
        print("2. Export each result to CSV in data/ folder")
        print("3. Run this script: python src/sql_results_visualizer.py")

if __name__ == "__main__":
    generate_all_visualizations()
