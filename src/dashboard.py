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

@st.cache_data
def load_anomaly_data():
    try:
        customer_anomaly = pd.read_csv(os.path.join(data_dir, 'customer_anomaly_detection.csv'))
        transaction_fraud = pd.read_csv(os.path.join(data_dir, 'transaction_fraud_detection.csv'))
        
        # Convert date columns
        if 'order_date' in transaction_fraud.columns:
            transaction_fraud['order_date'] = pd.to_datetime(transaction_fraud['order_date'])
        if 'payment_date' in transaction_fraud.columns:
            transaction_fraud['payment_date'] = pd.to_datetime(transaction_fraud['payment_date'])
        
        return customer_anomaly, transaction_fraud
    except Exception as e:
        return None, None

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
    st.markdown('<div class="main-header">🎯 Customer Payment Behaviour Analysis Dashboard</div>', unsafe_allow_html=True)
    st.markdown("### AI-Powered Customer Insights with Segmentation & Fraud Detection")
    
    # Load data
    try:
        df = load_data()
        customer_anomaly, transaction_fraud = load_anomaly_data()
    except Exception as e:
        st.error(f"Error loading data: {e}")
        st.info("Please ensure you have run the segmentation script first.")
        return
    
    # Sidebar
    st.sidebar.header("🔧 Dashboard Controls")
    
    # Add page selection
    page = st.sidebar.radio(
        "Select View",
        ["📊 Customer Segmentation", "🚨 Anomaly & Fraud Detection", "📈 Combined Analysis"]
    )
    
    st.sidebar.markdown("---")
    
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
    
    # Route to different pages
    if page == "📊 Customer Segmentation":
        show_segmentation_page(filtered_df, selected_segments, available_segments)
    elif page == "🚨 Anomaly & Fraud Detection":
        show_fraud_detection_page(customer_anomaly, transaction_fraud, df)
    else:
        show_combined_analysis_page(filtered_df, customer_anomaly, transaction_fraud, selected_segments, available_segments)

def show_segmentation_page(filtered_df, selected_segments, available_segments):
    """Original segmentation dashboard"""
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

def show_fraud_detection_page(customer_anomaly, transaction_fraud, df):
    """Fraud detection and anomaly analysis page"""
    if customer_anomaly is None or transaction_fraud is None:
        st.error("❌ Anomaly and fraud detection data not found!")
        st.info("Please run the `anomaly_fraud_detection.py` script first to generate the required data.")
        return
    
    st.markdown("---")
    st.subheader("🚨 Anomaly & Fraud Detection Overview")
    
    # Key metrics
    col1, col2, col3, col4 = st.columns(4)
    
    anomalous_customers = customer_anomaly[customer_anomaly['is_anomaly'] == True]
    fraudulent_txns = transaction_fraud[transaction_fraud['fraud_prediction'] == -1]
    high_risk_txns = transaction_fraud[transaction_fraud['fraud_risk_score'] > 70]
    
    with col1:
        st.metric("Total Customers", len(customer_anomaly))
    with col2:
        st.metric("Anomalous Customers", len(anomalous_customers), 
                 delta=f"{len(anomalous_customers)/len(customer_anomaly)*100:.1f}%")
    with col3:
        st.metric("Fraudulent Transactions", len(fraudulent_txns),
                 delta=f"{len(fraudulent_txns)/len(transaction_fraud)*100:.1f}%")
    with col4:
        st.metric("High-Risk Transactions", len(high_risk_txns))
    
    # Anomaly Detection Details
    st.markdown("---")
    st.subheader("👥 Customer-Level Anomaly Detection")
    
    col1, col2 = st.columns(2)
    
    with col1:
        # Anomaly consensus distribution
        consensus_counts = customer_anomaly['anomaly_consensus'].value_counts().sort_index()
        fig_consensus = px.bar(
            x=consensus_counts.index,
            y=consensus_counts.values,
            labels={'x': 'Number of Methods Flagging as Anomaly', 'y': 'Number of Customers'},
            title='Anomaly Detection Consensus',
            color=consensus_counts.values,
            color_continuous_scale='Reds'
        )
        fig_consensus.update_layout(showlegend=False)
        st.plotly_chart(fig_consensus, use_container_width=True)
    
    with col2:
        # Anomaly score distribution
        fig_scores = px.histogram(
            customer_anomaly,
            x='anomaly_score_iso_forest',
            nbins=30,
            title='Isolation Forest Anomaly Score Distribution',
            labels={'anomaly_score_iso_forest': 'Anomaly Score', 'count': 'Frequency'},
            color_discrete_sequence=['#3498db']
        )
        # Add threshold line
        if len(anomalous_customers) > 0:
            threshold = anomalous_customers['anomaly_score_iso_forest'].max()
            fig_scores.add_vline(x=threshold, line_dash="dash", line_color="red",
                               annotation_text="Anomaly Threshold")
        st.plotly_chart(fig_scores, use_container_width=True)
    
    # Top anomalous customers
    if len(anomalous_customers) > 0:
        st.markdown("#### 🔴 Top 10 Most Anomalous Customers")
        top_anomalies = customer_anomaly.nsmallest(10, 'anomaly_score_iso_forest')[
            ['customer_id', 'amount_sum', 'payment_delay_days_mean', 'payment_id_count', 
             'anomaly_score_iso_forest', 'anomaly_consensus', 'is_anomaly']
        ]
        st.dataframe(top_anomalies, use_container_width=True)
    
    # Transaction Fraud Detection
    st.markdown("---")
    st.subheader("💳 Transaction-Level Fraud Detection")
    
    col1, col2 = st.columns(2)
    
    with col1:
        # Fraud risk score distribution
        fig_fraud = px.histogram(
            transaction_fraud,
            x='fraud_risk_score',
            nbins=30,
            title='Transaction Fraud Risk Score Distribution',
            labels={'fraud_risk_score': 'Fraud Risk Score (0-100)', 'count': 'Number of Transactions'},
            color_discrete_sequence=['#e74c3c']
        )
        fig_fraud.add_vline(x=70, line_dash="dash", line_color="darkred",
                           annotation_text="High Risk Threshold")
        st.plotly_chart(fig_fraud, use_container_width=True)
    
    with col2:
        # Fraud by payment method
        fraud_method = transaction_fraud[transaction_fraud['fraud_prediction'] == -1]['method'].value_counts()
        normal_method = transaction_fraud[transaction_fraud['fraud_prediction'] == 1]['method'].value_counts()
        
        fig_method = go.Figure()
        fig_method.add_trace(go.Bar(name='Fraudulent', x=fraud_method.index, y=fraud_method.values, 
                                    marker_color='#e74c3c'))
        fig_method.add_trace(go.Bar(name='Normal', x=normal_method.index, y=normal_method.values,
                                    marker_color='#27ae60'))
        fig_method.update_layout(
            title='Payment Method: Fraudulent vs Normal Transactions',
            xaxis_title='Payment Method',
            yaxis_title='Number of Transactions',
            barmode='group'
        )
        st.plotly_chart(fig_method, use_container_width=True)
    
    # Top fraudulent transactions
    st.markdown("#### 🚨 Top 10 Most Suspicious Transactions")
    top_fraud = transaction_fraud.nlargest(10, 'fraud_risk_score')[
        ['payment_id', 'customer_id', 'order_id', 'amount', 'payment_delay_days', 
         'fraud_risk_score', 'method', 'fraud_prediction']
    ]
    st.dataframe(top_fraud, use_container_width=True)
    
    # Comparison charts
    st.markdown("---")
    st.subheader("📊 Anomalous vs Normal Behavior Comparison")
    
    comparison_features = ['amount_sum', 'payment_delay_days_mean', 'payment_id_count', 'recency_days']
    feature_labels = {
        'amount_sum': 'Total Payment Amount (HUF)',
        'payment_delay_days_mean': 'Avg Payment Delay (days)',
        'payment_id_count': 'Number of Payments',
        'recency_days': 'Recency (days)'
    }
    
    selected_feature = st.selectbox("Select feature to compare", comparison_features, 
                                    format_func=lambda x: feature_labels[x])
    
    fig_compare = go.Figure()
    
    normal_customers = customer_anomaly[customer_anomaly['is_anomaly'] == False]
    
    fig_compare.add_trace(go.Box(
        y=normal_customers[selected_feature],
        name='Normal',
        marker_color='lightblue'
    ))
    
    fig_compare.add_trace(go.Box(
        y=anomalous_customers[selected_feature],
        name='Anomalous',
        marker_color='lightcoral'
    ))
    
    fig_compare.update_layout(
        title=f'{feature_labels[selected_feature]}: Normal vs Anomalous Customers',
        yaxis_title=feature_labels[selected_feature],
        showlegend=True
    )
    
    st.plotly_chart(fig_compare, use_container_width=True)
    
    # Download options
    st.markdown("---")
    st.subheader("📥 Download Reports")
    
    col1, col2 = st.columns(2)
    
    with col1:
        if len(anomalous_customers) > 0:
            csv_anomaly = anomalous_customers.to_csv(index=False).encode('utf-8')
            st.download_button(
                label="Download Anomalous Customers Report",
                data=csv_anomaly,
                file_name="anomalous_customers.csv",
                mime="text/csv"
            )
    
    with col2:
        if len(high_risk_txns) > 0:
            csv_fraud = high_risk_txns.to_csv(index=False).encode('utf-8')
            st.download_button(
                label="Download High-Risk Transactions Report",
                data=csv_fraud,
                file_name="high_risk_transactions.csv",
                mime="text/csv"
            )

def show_combined_analysis_page(filtered_df, customer_anomaly, transaction_fraud, selected_segments, available_segments):
    """Combined view showing segments with anomaly/fraud overlay"""
    if customer_anomaly is None or transaction_fraud is None:
        st.warning("⚠️ Anomaly and fraud detection data not available. Showing segmentation only.")
        show_segmentation_page(filtered_df, selected_segments, available_segments)
        return
    
    st.markdown("---")
    st.subheader("📈 Combined Customer Analysis")
    
    # Merge segment with anomaly data
    combined_df = filtered_df.merge(
        customer_anomaly[['customer_id', 'is_anomaly', 'anomaly_score_iso_forest']], 
        on='customer_id', 
        how='left'
    )
    combined_df['is_anomaly'] = combined_df['is_anomaly'].fillna(False)
    
    # Calculate average fraud risk per customer from transactions
    if transaction_fraud is not None and 'fraud_risk_score' in transaction_fraud.columns:
        customer_fraud_risk = transaction_fraud.groupby('customer_id')['fraud_risk_score'].mean().reset_index()
        customer_fraud_risk.columns = ['customer_id', 'avg_fraud_risk']
        combined_df = combined_df.merge(customer_fraud_risk, on='customer_id', how='left')
        combined_df['avg_fraud_risk'] = combined_df['avg_fraud_risk'].fillna(0)
    
    # Overview metrics
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric("Total Customers", len(combined_df))
    with col2:
        st.metric("Anomalous", len(combined_df[combined_df['is_anomaly'] == True]))
    with col3:
        st.metric("Total Revenue", f"{combined_df['amount_sum'].sum():,.0f} HUF")
    with col4:
        avg_risk = combined_df['avg_fraud_risk'].mean() if 'avg_fraud_risk' in combined_df.columns else 0
        st.metric("Avg Fraud Risk", f"{avg_risk:.1f}/100")
    
    # Segment vs Anomaly distribution
    st.markdown("---")
    st.subheader("🎯 Segment Distribution with Anomaly Overlay")
    
    col1, col2 = st.columns(2)
    
    with col1:
        # Stacked bar: normal vs anomaly per segment
        segment_anomaly = combined_df.groupby(['segment', 'is_anomaly']).size().reset_index(name='count')
        segment_anomaly['segment_name'] = segment_anomaly['segment'].map(lambda x: SEGMENT_INFO[x]['name'])
        segment_anomaly['type'] = segment_anomaly['is_anomaly'].map({True: 'Anomalous', False: 'Normal'})
        
        fig_stack = px.bar(
            segment_anomaly,
            x='segment_name',
            y='count',
            color='type',
            title='Customer Distribution: Normal vs Anomalous by Segment',
            labels={'segment_name': 'Segment', 'count': 'Number of Customers', 'type': 'Customer Type'},
            color_discrete_map={'Normal': '#27ae60', 'Anomalous': '#e74c3c'},
            barmode='stack'
        )
        st.plotly_chart(fig_stack, use_container_width=True)
    
    with col2:
        # Anomaly rate by segment
        anomaly_rate = combined_df.groupby('segment').apply(
            lambda x: (x['is_anomaly'] == True).sum() / len(x) * 100
        ).reset_index(name='anomaly_rate')
        anomaly_rate['segment_name'] = anomaly_rate['segment'].map(lambda x: SEGMENT_INFO[x]['name'])
        
        fig_rate = px.bar(
            anomaly_rate,
            x='segment_name',
            y='anomaly_rate',
            title='Anomaly Rate by Segment (%)',
            labels={'segment_name': 'Segment', 'anomaly_rate': 'Anomaly Rate (%)'},
            color='anomaly_rate',
            color_continuous_scale='Reds'
        )
        st.plotly_chart(fig_rate, use_container_width=True)
    
    # Interactive scatter: Segments with anomaly highlighting
    st.markdown("---")
    st.subheader("🗺️ Customer Segmentation Map with Anomaly Detection")
    
    combined_df['segment_name'] = combined_df['segment'].map(lambda x: SEGMENT_INFO[x]['name'])
    combined_df['status'] = combined_df['is_anomaly'].map({True: '🔴 Anomalous', False: '✅ Normal'})
    
    fig_scatter = px.scatter(
        combined_df,
        x='pca_1',
        y='pca_2',
        color='segment_name',
        symbol='status',
        title='Customer Segments with Anomaly Detection',
        labels={'pca_1': 'Principal Component 1', 'pca_2': 'Principal Component 2'},
        color_discrete_map={SEGMENT_INFO[seg]['name']: SEGMENT_INFO[seg]['color'] for seg in available_segments},
        hover_data=['customer_id', 'amount_sum', 'payment_delay_days_mean', 'is_anomaly']
    )
    fig_scatter.update_traces(marker=dict(size=10, opacity=0.7, line=dict(width=1, color='white')))
    st.plotly_chart(fig_scatter, use_container_width=True)
    
    # Detailed table with risk scores
    st.markdown("---")
    st.subheader("📋 Customer Details with Risk Assessment")
    
    if st.checkbox("Show detailed customer data with risk scores"):
        display_columns = [
            'customer_id', 'segment', 'segment_name', 'amount_sum', 
            'payment_delay_days_mean', 'payment_id_count', 'is_anomaly',
            'anomaly_score_iso_forest'
        ]
        
        # Sort by anomaly score (most suspicious first)
        display_df = combined_df[display_columns].sort_values('anomaly_score_iso_forest')
        st.dataframe(display_df, use_container_width=True)
        
        # Download combined report
        csv_combined = combined_df.to_csv(index=False).encode('utf-8')
        st.download_button(
            label="📥 Download Combined Analysis Report",
            data=csv_combined,
            file_name="combined_segment_anomaly_analysis.csv",
            mime="text/csv"
        )

if __name__ == "__main__":
    main()
