import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import os

# Page configuration
st.set_page_config(
    page_title="Customer Payment Behaviour Segmentation",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
        text-align: center;
        padding: 20px;
    }
    .segment-card {
        padding: 20px;
        border-radius: 10px;
        background-color: #f0f2f6;
        margin: 10px 0;
    }
    .metric-container {
        text-align: center;
    }
</style>
""", unsafe_allow_html=True)

# Get data directory
script_dir = os.path.dirname(os.path.abspath(__file__))
data_dir = os.path.abspath(os.path.join(script_dir, '..', 'data'))

# Load data
@st.cache_data
def load_data():
    customer_segments = pd.read_csv(os.path.join(data_dir, 'customer_segments.csv'))
    
    # Convert date columns
    date_columns = ['payment_date_min', 'payment_date_max', 'reg_date_first']
    for col in date_columns:
        if col in customer_segments.columns:
            customer_segments[col] = pd.to_datetime(customer_segments[col])
    
    return customer_segments

# Segment names and descriptions
SEGMENT_INFO = {
    0: {
        'name': 'Problem Customers',
        'color': '#e74c3c',
        'description': 'High payment delays, low activity, credit risk',
        'recommendation': 'Implement stricter credit policies, send payment reminders, consider collection actions'
    },
    1: {
        'name': 'VIP Customers',
        'color': '#27ae60',
        'description': 'Most active, highest spending, early payers',
        'recommendation': 'Offer loyalty rewards, exclusive deals, priority support'
    },
    2: {
        'name': 'Churned/Inactive',
        'color': '#95a5a6',
        'description': 'No recent activity, risk of permanent loss',
        'recommendation': 'Launch re-engagement campaigns, special comeback offers, surveys'
    },
    3: {
        'name': 'Standard Customers',
        'color': '#3498db',
        'description': 'Moderate activity, slight payment delays',
        'recommendation': 'Maintain relationship, encourage more frequent purchases, payment reminders'
    }
}

# Main app
def main():
    st.markdown('<div class="main-header">🎯 Customer Payment Behaviour Segmentation Dashboard</div>', unsafe_allow_html=True)
    st.markdown("### AI-Powered Customer Insights using K-Means Clustering")
    
    # Load data
    try:
        df = load_data()
    except Exception as e:
        st.error(f"Error loading data: {e}")
        st.info("Please ensure you have run the segmentation script first.")
        return
    
    # Sidebar
    st.sidebar.header("🔧 Dashboard Controls")
    
    # Segment filter
    available_segments = sorted(df['segment'].unique())
    segment_names = [f"Segment {seg}: {SEGMENT_INFO[seg]['name']}" for seg in available_segments]
    
    selected_segments = st.sidebar.multiselect(
        "Select Segments to Display",
        options=available_segments,
        default=available_segments,
        format_func=lambda x: f"Segment {x}: {SEGMENT_INFO[x]['name']}"
    )
    
    if not selected_segments:
        st.warning("Please select at least one segment.")
        return
    
    filtered_df = df[df['segment'].isin(selected_segments)]
    
    # Overview metrics
    st.markdown("---")
    st.subheader("📈 Overview Metrics")
    
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Customers", len(filtered_df))
    with col2:
        st.metric("Total Orders", int(filtered_df['order_id_nunique'].sum()))
    with col3:
        st.metric("Total Payments", int(filtered_df['payment_id_count'].sum()))
    with col4:
        st.metric("Total Revenue", f"{filtered_df['amount_sum'].sum():,.0f} HUF")
    
    # Segment distribution
    st.markdown("---")
    st.subheader("🎨 Segment Distribution")
    
    col1, col2 = st.columns(2)
    
    with col1:
        # Pie chart
        segment_counts = filtered_df['segment'].value_counts().reset_index()
        segment_counts.columns = ['segment', 'count']
        segment_counts['name'] = segment_counts['segment'].map(lambda x: SEGMENT_INFO[x]['name'])
        segment_counts['color'] = segment_counts['segment'].map(lambda x: SEGMENT_INFO[x]['color'])
        
        fig_pie = px.pie(
            segment_counts, 
            values='count', 
            names='name',
            title='Customer Distribution by Segment',
            color='name',
            color_discrete_map={SEGMENT_INFO[seg]['name']: SEGMENT_INFO[seg]['color'] for seg in available_segments}
        )
        fig_pie.update_traces(textposition='inside', textinfo='percent+label')
        st.plotly_chart(fig_pie, use_container_width=True)
    
    with col2:
        # Bar chart
        fig_bar = px.bar(
            segment_counts,
            x='name',
            y='count',
            title='Customer Count by Segment',
            color='name',
            color_discrete_map={SEGMENT_INFO[seg]['name']: SEGMENT_INFO[seg]['color'] for seg in available_segments},
            text='count'
        )
        fig_bar.update_traces(textposition='outside')
        fig_bar.update_layout(showlegend=False, xaxis_title='Segment', yaxis_title='Number of Customers')
        st.plotly_chart(fig_bar, use_container_width=True)
    
    # PCA visualization
    st.markdown("---")
    st.subheader("🗺️ Customer Segmentation Map (PCA)")
    
    filtered_df['segment_name'] = filtered_df['segment'].map(lambda x: SEGMENT_INFO[x]['name'])
    
    fig_pca = px.scatter(
        filtered_df,
        x='pca_1',
        y='pca_2',
        color='segment_name',
        title='Customer Segments in 2D Space',
        labels={'pca_1': 'Principal Component 1', 'pca_2': 'Principal Component 2'},
        color_discrete_map={SEGMENT_INFO[seg]['name']: SEGMENT_INFO[seg]['color'] for seg in available_segments},
        hover_data=['customer_id', 'amount_sum', 'payment_id_count', 'payment_delay_days_mean']
    )
    fig_pca.update_traces(marker=dict(size=10, opacity=0.7, line=dict(width=1, color='white')))
    st.plotly_chart(fig_pca, use_container_width=True)
    
    # Segment profiles
    st.markdown("---")
    st.subheader("📊 Detailed Segment Profiles")
    
    for segment in selected_segments:
        segment_data = filtered_df[filtered_df['segment'] == segment]
        info = SEGMENT_INFO[segment]
        
        with st.expander(f"**Segment {segment}: {info['name']}** ({len(segment_data)} customers)", expanded=True):
            st.markdown(f"<div class='segment-card'>", unsafe_allow_html=True)
            
            # Description and recommendation
            col1, col2 = st.columns(2)
            with col1:
                st.markdown(f"**📝 Description:** {info['description']}")
            with col2:
                st.markdown(f"**💡 Recommendation:** {info['recommendation']}")
            
            st.markdown("---")
            
            # Key metrics
            col1, col2, col3, col4, col5 = st.columns(5)
            with col1:
                st.metric("Avg Orders", f"{segment_data['order_id_nunique'].mean():.2f}")
            with col2:
                st.metric("Avg Payments", f"{segment_data['payment_id_count'].mean():.2f}")
            with col3:
                st.metric("Avg Revenue", f"{segment_data['amount_sum'].mean():.0f} HUF")
            with col4:
                st.metric("Avg Delay", f"{segment_data['payment_delay_days_mean'].mean():.1f} days")
            with col5:
                st.metric("Avg Recency", f"{segment_data['recency_days'].mean():.0f} days")
            
            st.markdown("</div>", unsafe_allow_html=True)
    
    # Feature comparison
    st.markdown("---")
    st.subheader("📉 Feature Comparison Across Segments")
    
    # Select features to compare
    feature_options = [
        'order_id_nunique', 'payment_id_count', 'amount_sum', 'amount_mean',
        'payment_delay_days_mean', 'recency_days', 'payment_frequency'
    ]
    
    feature_labels = {
        'order_id_nunique': 'Number of Orders',
        'payment_id_count': 'Number of Payments',
        'amount_sum': 'Total Payment Amount',
        'amount_mean': 'Average Payment Amount',
        'payment_delay_days_mean': 'Average Payment Delay (days)',
        'recency_days': 'Recency (days)',
        'payment_frequency': 'Payment Frequency'
    }
    
    selected_features = st.multiselect(
        "Select features to compare",
        options=feature_options,
        default=['amount_sum', 'payment_delay_days_mean', 'payment_frequency'],
        format_func=lambda x: feature_labels[x]
    )
    
    if selected_features:
        # Create subplots
        fig = make_subplots(
            rows=len(selected_features),
            cols=1,
            subplot_titles=[feature_labels[f] for f in selected_features],
            vertical_spacing=0.1
        )
        
        for idx, feature in enumerate(selected_features, 1):
            segment_means = filtered_df.groupby('segment')[feature].mean().reset_index()
            segment_means['name'] = segment_means['segment'].map(lambda x: SEGMENT_INFO[x]['name'])
            segment_means['color'] = segment_means['segment'].map(lambda x: SEGMENT_INFO[x]['color'])
            
            for _, row in segment_means.iterrows():
                fig.add_trace(
                    go.Bar(
                        x=[row['name']],
                        y=[row[feature]],
                        name=row['name'],
                        marker_color=row['color'],
                        showlegend=(idx == 1)
                    ),
                    row=idx,
                    col=1
                )
        
        fig.update_layout(height=300 * len(selected_features), showlegend=True)
        st.plotly_chart(fig, use_container_width=True)
    
    # Payment method distribution
    st.markdown("---")
    st.subheader("💳 Payment Method Distribution by Segment")
    
    method_dist = filtered_df.groupby(['segment', 'preferred_method']).size().reset_index(name='count')
    method_dist['segment_name'] = method_dist['segment'].map(lambda x: SEGMENT_INFO[x]['name'])
    
    fig_method = px.bar(
        method_dist,
        x='segment_name',
        y='count',
        color='preferred_method',
        title='Preferred Payment Methods by Segment',
        labels={'segment_name': 'Segment', 'count': 'Number of Customers', 'preferred_method': 'Payment Method'},
        barmode='group'
    )
    st.plotly_chart(fig_method, use_container_width=True)
    
    # Raw data viewer
    st.markdown("---")
    st.subheader("📋 Raw Data Viewer")
    
    if st.checkbox("Show raw customer data"):
        # Select columns to display
        display_columns = [
            'customer_id', 'segment', 'segment_name', 'order_id_nunique', 
            'payment_id_count', 'amount_sum', 'payment_delay_days_mean', 
            'recency_days', 'preferred_method'
        ]
        
        st.dataframe(
            filtered_df[display_columns].sort_values('segment'),
            use_container_width=True
        )
        
        # Download button
        csv = filtered_df.to_csv(index=False).encode('utf-8')
        st.download_button(
            label="📥 Download Segmented Data as CSV",
            data=csv,
            file_name="customer_segments.csv",
            mime="text/csv"
        )

if __name__ == "__main__":
    main()
