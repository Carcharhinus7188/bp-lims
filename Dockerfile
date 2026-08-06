# BPLab Trace — Production Docker Image
# Build:  docker build -t bplab-trace .
# Run:    docker run -p 8501:8501 -v $(pwd)/data:/app/data bplab-trace

# ---------- Stage 1: Build ----------
FROM python:3.12-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies in a separate layer for caching
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ---------- Stage 2: Production ----------
FROM python:3.12-slim

# Install CJK fonts for Chinese character rendering in PDFs/images
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY app.py .
COPY config.py .
COPY logging_config.py .
COPY constants.py .
COPY lims_db.py .
COPY business_record_engine.py .
COPY business_record_ui.py .
COPY camera_evidence.py .
COPY controlled_template_mappings.py .
COPY docx_preview.py .
COPY equipment_registry.py .
COPY experiment_engine.py .
COPY experiment_schemas.py .
COPY form_engine.py .
COPY pdf_preview.py .
COPY quick_demo.py .
COPY record_word_engine.py .
COPY report_rules.py .
COPY template_record_engine.py .
COPY trace_excel_engine.py .

# Copy templates and seed data
COPY templates/ ./templates/
COPY sample_catalog_seed.json .
COPY equipment_binding_matrix.csv .
COPY equipment_master.csv .

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash appuser \
    && mkdir -p /app/data /app/logs /app/data/attachments /app/data/signatures /app/data/outputs \
    && chown -R appuser:appuser /app

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8501/_stcore/health')" || exit 1

EXPOSE 8501

ENV STREAMLIT_SERVER_PORT=8501 \
    STREAMLIT_SERVER_ADDRESS=0.0.0.0 \
    STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_BROWSER_GATHER_USAGE_STATS=false \
    BPLAB_DEMO_MODE=false

# Streamlit run command (can be overridden)
ENTRYPOINT ["streamlit", "run", "app.py"]
