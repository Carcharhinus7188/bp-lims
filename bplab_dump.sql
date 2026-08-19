--
-- PostgreSQL database dump
--

\restrict sPxvpUFfT8lgrConPFxYg9Ne9DrjMj22xFezYhlVM4v7Hp0b8L6Dx9Sj5Qxoyfj

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attachments (
    id integer NOT NULL,
    attachment_id text,
    commission_no text,
    package_no text,
    task_no text,
    sample_no text,
    attachment_type text,
    original_name text,
    stored_name text,
    relative_path text,
    sha256 text,
    captured_at timestamp with time zone,
    uploader text,
    description text,
    is_original boolean DEFAULT true,
    parent_attachment_id text,
    capture_source text DEFAULT 'file'::text,
    checkpoint_code text,
    checkpoint_label text,
    device_id text,
    evidence_status text DEFAULT '有效'::text,
    server_captured_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attachments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attachments_id_seq OWNED BY public.attachments.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    entity_type text,
    entity_id text,
    actor text,
    actor_name text,
    actor_role text,
    action text,
    field_name text,
    old_value text,
    new_value text,
    reason text,
    client_time text,
    device_id text,
    session_token text,
    snapshot_hash text,
    previous_hash text,
    entry_hash text,
    created_at timestamp with time zone DEFAULT now(),
    commission_no text
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: commissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commissions (
    commission_no text NOT NULL,
    client_org_id integer NOT NULL,
    client_name text NOT NULL,
    client_address text,
    contact text,
    phone text,
    production_org_id integer NOT NULL,
    production_org_name text NOT NULL,
    production_relation text NOT NULL,
    commission_date date,
    due_date date,
    subcontract_allowed text,
    report_medium text,
    conformity_judgment text,
    uncertainty text,
    delivery_method text,
    cnas_mark text,
    capability text,
    method_choices jsonb DEFAULT '[]'::jsonb,
    notes text,
    status text DEFAULT '已入库'::text,
    created_by text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    archived_at timestamp with time zone,
    archived_by text
);


--
-- Name: device_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.device_presets (
    experiment text NOT NULL,
    equipment_name text,
    equipment_model text,
    equipment_no text,
    calibration_certificate text,
    calibration_due text,
    software text,
    default_location text,
    extra_json jsonb DEFAULT '{}'::jsonb,
    updated_by text,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: document_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_versions (
    id integer NOT NULL,
    entity_type text,
    entity_id text,
    version integer,
    status text,
    snapshot_json jsonb,
    snapshot_hash text,
    created_by text,
    created_at timestamp with time zone DEFAULT now(),
    obsolete_by text,
    obsolete_at timestamp with time zone
);


--
-- Name: document_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.document_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: document_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.document_versions_id_seq OWNED BY public.document_versions.id;


--
-- Name: equipment_incident_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipment_incident_actions (
    id integer NOT NULL,
    incident_no text NOT NULL,
    actor text,
    action text,
    comment text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: equipment_incident_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.equipment_incident_actions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: equipment_incident_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.equipment_incident_actions_id_seq OWNED BY public.equipment_incident_actions.id;


--
-- Name: equipment_incidents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipment_incidents (
    incident_no text NOT NULL,
    task_no text,
    equipment_no text,
    fault_type text,
    fault_description text,
    status text DEFAULT '报告'::text,
    quality_conclusion text,
    impact_scope text,
    recovery_route text,
    created_by text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    package_no text,
    group_id integer,
    equipment_name text,
    reporter text,
    occurred_at timestamp with time zone,
    error_code text,
    current_stage text,
    completed_steps text,
    collected_data text,
    sample_condition text,
    risk_types jsonb DEFAULT '[]'::jsonb,
    immediate_actions jsonb DEFAULT '[]'::jsonb,
    involved_samples jsonb DEFAULT '[]'::jsonb,
    frozen_record_version integer,
    isolation_location text,
    storage_requirements text,
    sample_validity text,
    receiver_note text,
    receiver_by text,
    receiver_at timestamp with time zone,
    quality_note text,
    quality_by text,
    quality_at timestamp with time zone,
    backup_equipment_no text,
    performance_check_result text,
    admin_note text,
    approved_by text,
    approved_at timestamp with time zone,
    resumed_record_version integer,
    closed_at timestamp with time zone
);


--
-- Name: equipment_registry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipment_registry (
    management_no text NOT NULL,
    seq integer,
    equipment_name text NOT NULL,
    model text,
    measuring_range text,
    manufacturer text,
    serial_no text,
    purchase_time text,
    calibration_time text,
    responsible text,
    equipment_class text,
    enabled boolean DEFAULT true,
    lifecycle_status text DEFAULT '启用'::text,
    status_note text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    calibration_due text,
    calibration_certificate text
);


--
-- Name: experiment_config_columns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_config_columns (
    id integer NOT NULL,
    config_id integer NOT NULL,
    column_key text NOT NULL,
    column_label text NOT NULL,
    column_type text DEFAULT 'number'::text NOT NULL,
    is_required boolean DEFAULT false,
    column_default text,
    calc_expression text,
    calc_precision integer DEFAULT 3,
    sort_order integer DEFAULT 0
);


--
-- Name: experiment_config_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.experiment_config_columns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: experiment_config_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.experiment_config_columns_id_seq OWNED BY public.experiment_config_columns.id;


--
-- Name: experiment_config_equipment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_config_equipment (
    config_id integer NOT NULL,
    management_no text NOT NULL,
    binding_role text NOT NULL,
    required boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    note text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: experiment_config_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_config_fields (
    id integer NOT NULL,
    config_id integer NOT NULL,
    section_title text DEFAULT ''::text NOT NULL,
    section_order integer DEFAULT 1 NOT NULL,
    field_key text NOT NULL,
    field_label text NOT NULL,
    field_type text DEFAULT 'text'::text NOT NULL,
    field_default text DEFAULT ''::text,
    field_options text DEFAULT ''::text,
    is_required boolean DEFAULT false,
    is_readonly boolean DEFAULT false,
    is_actual boolean DEFAULT false,
    sort_order integer DEFAULT 0
);


--
-- Name: experiment_config_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.experiment_config_fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: experiment_config_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.experiment_config_fields_id_seq OWNED BY public.experiment_config_fields.id;


--
-- Name: experiment_config_photo_checkpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_config_photo_checkpoints (
    id integer NOT NULL,
    config_id integer NOT NULL,
    checkpoint_code text NOT NULL,
    checkpoint_label text NOT NULL,
    is_required boolean DEFAULT true,
    is_sample_level boolean DEFAULT false,
    checkpoint_group text,
    sort_order integer DEFAULT 0
);


--
-- Name: experiment_config_photo_checkpoints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.experiment_config_photo_checkpoints_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: experiment_config_photo_checkpoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.experiment_config_photo_checkpoints_id_seq OWNED BY public.experiment_config_photo_checkpoints.id;


--
-- Name: experiment_config_prechecks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_config_prechecks (
    id integer NOT NULL,
    config_id integer NOT NULL,
    precheck_code text NOT NULL,
    precheck_label text NOT NULL,
    is_required boolean DEFAULT true,
    sort_order integer DEFAULT 0
);


--
-- Name: experiment_config_prechecks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.experiment_config_prechecks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: experiment_config_prechecks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.experiment_config_prechecks_id_seq OWNED BY public.experiment_config_prechecks.id;


--
-- Name: experiment_config_validation_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_config_validation_rules (
    id integer NOT NULL,
    config_id integer NOT NULL,
    rule_type text NOT NULL,
    target_field text NOT NULL,
    rule_value text NOT NULL,
    error_message text,
    is_row_level boolean DEFAULT false
);


--
-- Name: experiment_config_validation_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.experiment_config_validation_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: experiment_config_validation_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.experiment_config_validation_rules_id_seq OWNED BY public.experiment_config_validation_rules.id;


--
-- Name: experiment_config_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_config_versions (
    id integer NOT NULL,
    experiment_code text NOT NULL,
    version text NOT NULL,
    experiment_name text NOT NULL,
    method_code text NOT NULL,
    standard text,
    category text,
    kind text DEFAULT 'generic'::text,
    default_location text,
    sop_version text,
    record_template_version text,
    software text,
    status text DEFAULT '草稿'::text,
    effective_date date,
    note text,
    created_by text,
    created_at timestamp with time zone DEFAULT now(),
    approved_by text,
    approved_at timestamp with time zone,
    extra_json jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT experiment_config_versions_status_check CHECK ((status = ANY (ARRAY['草稿'::text, '现行'::text, '历史'::text])))
);


--
-- Name: experiment_config_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.experiment_config_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: experiment_config_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.experiment_config_versions_id_seq OWNED BY public.experiment_config_versions.id;


--
-- Name: experiment_equipment_bindings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_equipment_bindings (
    experiment text NOT NULL,
    management_no text NOT NULL,
    binding_role text NOT NULL,
    required boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    note text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: experiment_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_methods (
    experiment_code text NOT NULL,
    experiment_name text NOT NULL,
    method_code text NOT NULL,
    standard text,
    category text,
    kind text,
    enabled boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    template_code text,
    sop_file text
);


--
-- Name: experiment_standards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiment_standards (
    id integer NOT NULL,
    experiment_code text NOT NULL,
    standard text NOT NULL,
    enabled boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: experiment_standards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.experiment_standards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: experiment_standards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.experiment_standards_id_seq OWNED BY public.experiment_standards.id;


--
-- Name: form_drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.form_drafts (
    session_token text NOT NULL,
    page text NOT NULL,
    draft_key text NOT NULL,
    payload jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: hazardous_waste_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hazardous_waste_records (
    disposal_no text NOT NULL,
    commission_no text,
    task_no text,
    task_nos jsonb DEFAULT '[]'::jsonb,
    sample_no text,
    waste_type text,
    waste_name text,
    quantity real,
    unit text,
    hazard_category text,
    disposal_method text,
    container_no text,
    handler text,
    occurred_at timestamp with time zone DEFAULT now(),
    status text DEFAULT '已登记'::text,
    created_at timestamp with time zone DEFAULT now(),
    note text,
    created_by text,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: modification_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modification_logs (
    id integer NOT NULL,
    entity_type text,
    entity_id text,
    actor text,
    action text,
    field_name text,
    old_value text,
    new_value text,
    reason text,
    created_at timestamp with time zone DEFAULT now(),
    commission_no text
);


--
-- Name: modification_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.modification_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: modification_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.modification_logs_id_seq OWNED BY public.modification_logs.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    recipient text NOT NULL,
    title text,
    message text,
    entity_type text,
    entity_id text,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: objection_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.objection_actions (
    id integer NOT NULL,
    objection_no text NOT NULL,
    actor text,
    action text,
    comment text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: objection_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.objection_actions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: objection_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.objection_actions_id_seq OWNED BY public.objection_actions.id;


--
-- Name: objections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.objections (
    objection_no text NOT NULL,
    report_no text,
    commission_no text,
    client_name text,
    contact text,
    description text,
    evidence_note text,
    status text DEFAULT '待处理'::text,
    pathway text,
    investigation text,
    trace_conclusion text,
    quality_conclusion text,
    quality_comment text,
    response_body text,
    admin_decision text,
    customer_retest_decision text,
    retest_task_no text,
    final_conclusion text,
    response_sent_at timestamp with time zone,
    archived_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    submitted_at timestamp with time zone,
    quality_inspector text,
    disputed_items text,
    involved_samples text,
    application_channel text,
    quality_evidence text,
    quality_method_check text,
    quality_equipment_check text,
    quality_environment_check text,
    quality_operation_check text,
    quality_calculation_check text,
    impact_scope text,
    treatment_suggestion text,
    retest_note text,
    customer_contact_at timestamp with time zone,
    customer_contact_method text,
    replacement_report_no text,
    response_text text,
    response_method text,
    response_receipt text,
    registered_by text,
    investigated_at timestamp with time zone,
    approved_by text,
    approved_at timestamp with time zone,
    sent_by text,
    sent_at timestamp with time zone,
    evidence_frozen_at timestamp with time zone,
    evidence_snapshot jsonb DEFAULT '{}'::jsonb
);


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id integer NOT NULL,
    org_code text,
    org_name text NOT NULL,
    short_name text,
    is_client boolean DEFAULT false,
    is_manufacturer boolean DEFAULT false,
    is_contract_manufacturer boolean DEFAULT false,
    address text,
    contact text,
    phone text,
    credit_code text,
    notes text,
    enabled boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organizations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organizations_id_seq OWNED BY public.organizations.id;


--
-- Name: package_loans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.package_loans (
    id integer NOT NULL,
    package_no text NOT NULL,
    sample_no text NOT NULL,
    borrower text,
    borrowed_at timestamp with time zone DEFAULT now(),
    purpose text,
    detection_location text,
    issue_note text,
    return_condition text,
    return_note text,
    returned_by text,
    returned_at timestamp with time zone,
    return_status text DEFAULT '未归还'::text,
    confirmed_by text,
    confirmed_at timestamp with time zone,
    confirmed_location text
);


--
-- Name: package_loans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.package_loans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: package_loans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.package_loans_id_seq OWNED BY public.package_loans.id;


--
-- Name: records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.records (
    id integer NOT NULL,
    record_no text NOT NULL,
    task_no text NOT NULL,
    version integer NOT NULL,
    experiment text,
    owner text,
    status text,
    payload jsonb,
    template_version text,
    sop_version text,
    change_reason text,
    tester_signed_at timestamp with time zone,
    reviewer_signed_at timestamp with time zone,
    quality_signed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.records_id_seq OWNED BY public.records.id;


--
-- Name: report_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_actions (
    id integer NOT NULL,
    report_no text NOT NULL,
    actor text,
    action text,
    comment text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: report_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_actions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_actions_id_seq OWNED BY public.report_actions.id;


--
-- Name: report_deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_deliveries (
    id integer NOT NULL,
    report_no text NOT NULL,
    client_name text,
    delivery_method text,
    recipient text,
    recipient_contact text,
    delivered_at timestamp with time zone DEFAULT now(),
    receipt_status text,
    receipt_note text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: report_deliveries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_deliveries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_deliveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_deliveries_id_seq OWNED BY public.report_deliveries.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    report_no text NOT NULL,
    commission_no text NOT NULL,
    task_no text,
    status text DEFAULT '草稿'::text,
    tester text,
    verifier text,
    quality_inspector text,
    approver text,
    source_versions text,
    validity_status text DEFAULT '现行有效'::text,
    supersedes_report_no text,
    report_category text DEFAULT '常规'::text,
    sample_statement text,
    conclusion text,
    notes text,
    signed_by_tester timestamp with time zone,
    signed_by_verifier timestamp with time zone,
    signed_by_quality timestamp with time zone,
    signed_by_approver timestamp with time zone,
    publish_date date,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    archived_at timestamp with time zone,
    approver_signature text
);


--
-- Name: requested_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requested_tests (
    id integer NOT NULL,
    group_id integer NOT NULL,
    experiment_code text NOT NULL,
    experiment text NOT NULL,
    method_code text NOT NULL,
    standard text,
    status text DEFAULT '待分配'::text,
    task_no text
);


--
-- Name: requested_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.requested_tests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requested_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.requested_tests_id_seq OWNED BY public.requested_tests.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews (
    id integer NOT NULL,
    record_no text,
    version integer,
    reviewer text,
    decision text,
    comment text,
    correction_fields jsonb DEFAULT '[]'::jsonb,
    reviewed_at timestamp with time zone DEFAULT now()
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: sample_catalog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sample_catalog (
    id integer NOT NULL,
    sample_code text,
    sample_name text NOT NULL,
    model text NOT NULL,
    material_name text NOT NULL,
    process text,
    material_suffix text,
    source_sequence text,
    category text,
    unit text DEFAULT '件'::text,
    experiment_codes jsonb DEFAULT '[]'::jsonb,
    notes text,
    enabled boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    detection_method text,
    detection_basis text
);


--
-- Name: sample_catalog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sample_catalog_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sample_catalog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sample_catalog_id_seq OWNED BY public.sample_catalog.id;


--
-- Name: sample_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sample_events (
    id integer NOT NULL,
    sample_no text,
    actor text,
    action text,
    from_status text,
    to_status text,
    from_location text,
    to_location text,
    details text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: sample_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sample_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sample_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sample_events_id_seq OWNED BY public.sample_events.id;


--
-- Name: sample_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sample_groups (
    id integer NOT NULL,
    group_no text NOT NULL,
    commission_no text NOT NULL,
    catalog_id integer,
    sample_name text,
    model text,
    material_name text,
    production_org_id integer,
    production_org_name text,
    production_relation text,
    product_no text,
    production_date text,
    quantity integer,
    unit text,
    condition text,
    condition_note text,
    storage_area text,
    notes text,
    status text DEFAULT '待分配'::text,
    is_void boolean DEFAULT false,
    void_by text,
    void_at timestamp with time zone,
    void_reason text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    experiment_codes text,
    batch_no text
);


--
-- Name: sample_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sample_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sample_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sample_groups_id_seq OWNED BY public.sample_groups.id;


--
-- Name: samples; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.samples (
    sample_no text NOT NULL,
    group_id integer NOT NULL,
    group_no text NOT NULL,
    commission_no text NOT NULL,
    sample_name text,
    model text,
    material_name text,
    condition text,
    condition_note text,
    current_location text,
    current_holder text,
    status text DEFAULT '待分配'::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    retention_period text,
    retention_until date,
    disposal_method text,
    disposal_date date,
    disposal_note text,
    disposed_by text
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    token text NOT NULL,
    username text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_activity_at timestamp with time zone
);


--
-- Name: signatures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.signatures (
    username text NOT NULL,
    source_file text,
    image_file text,
    uploaded_by text,
    uploaded_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: task_config_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_config_snapshots (
    task_no text NOT NULL,
    config_id integer,
    config_version text,
    snapshot_json jsonb NOT NULL,
    snapshot_hash text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: task_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_packages (
    package_no text NOT NULL,
    commission_no text NOT NULL,
    group_id integer NOT NULL,
    group_no text NOT NULL,
    assignee text NOT NULL,
    reviewer text NOT NULL,
    quality_inspector text,
    material_name text,
    sample_nos text,
    experiment_codes text,
    experiments text,
    status text DEFAULT '待接收'::text,
    assigned_by text,
    assigned_at timestamp with time zone DEFAULT now(),
    notified_at timestamp with time zone,
    accepted_at timestamp with time zone,
    detection_location text,
    acceptance_result text,
    acceptance_note text,
    return_submitted_at timestamp with time zone,
    return_confirmed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    sample_name text
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    task_no text NOT NULL,
    package_no text NOT NULL,
    commission_no text NOT NULL,
    group_id integer NOT NULL,
    group_no text NOT NULL,
    sample_nos text,
    experiment_code text NOT NULL,
    experiment text,
    method_code text,
    standard text,
    material_name text,
    assignee text,
    reviewer text,
    quality_inspector text,
    status text DEFAULT '待接收'::text,
    detection_location text,
    experiment_started_at timestamp with time zone,
    experiment_ended_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    sample_name text
);


--
-- Name: template_field_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.template_field_mappings (
    id integer NOT NULL,
    config_id integer NOT NULL,
    field_source text DEFAULT 'params'::text NOT NULL,
    field_key text NOT NULL,
    template_name text NOT NULL,
    table_index integer NOT NULL,
    row_index integer NOT NULL,
    col_index integer NOT NULL,
    transform text DEFAULT 'text'::text NOT NULL,
    checkbox_selection text DEFAULT ''::text,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);


--
-- Name: template_field_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.template_field_mappings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: template_field_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.template_field_mappings_id_seq OWNED BY public.template_field_mappings.id;


--
-- Name: template_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.template_versions (
    experiment text NOT NULL,
    doc_type text NOT NULL,
    file_name text NOT NULL,
    version text DEFAULT 'A/0'::text NOT NULL,
    effective_date date,
    status text DEFAULT '现行'::text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT template_versions_doc_type_check CHECK ((doc_type = ANY (ARRAY['原始记录表'::text, 'SOP'::text])))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    username text NOT NULL,
    display_name text NOT NULL,
    password_hash text NOT NULL,
    role text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_role_check CHECK ((role = ANY (ARRAY['管理员'::text, '样品管理员'::text, '实验员'::text, '复核员'::text, '质量负责人'::text, '授权签字人'::text])))
);


--
-- Name: attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments ALTER COLUMN id SET DEFAULT nextval('public.attachments_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: document_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_versions ALTER COLUMN id SET DEFAULT nextval('public.document_versions_id_seq'::regclass);


--
-- Name: equipment_incident_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_incident_actions ALTER COLUMN id SET DEFAULT nextval('public.equipment_incident_actions_id_seq'::regclass);


--
-- Name: experiment_config_columns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_columns ALTER COLUMN id SET DEFAULT nextval('public.experiment_config_columns_id_seq'::regclass);


--
-- Name: experiment_config_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_fields ALTER COLUMN id SET DEFAULT nextval('public.experiment_config_fields_id_seq'::regclass);


--
-- Name: experiment_config_photo_checkpoints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_photo_checkpoints ALTER COLUMN id SET DEFAULT nextval('public.experiment_config_photo_checkpoints_id_seq'::regclass);


--
-- Name: experiment_config_prechecks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_prechecks ALTER COLUMN id SET DEFAULT nextval('public.experiment_config_prechecks_id_seq'::regclass);


--
-- Name: experiment_config_validation_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_validation_rules ALTER COLUMN id SET DEFAULT nextval('public.experiment_config_validation_rules_id_seq'::regclass);


--
-- Name: experiment_config_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_versions ALTER COLUMN id SET DEFAULT nextval('public.experiment_config_versions_id_seq'::regclass);


--
-- Name: experiment_standards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_standards ALTER COLUMN id SET DEFAULT nextval('public.experiment_standards_id_seq'::regclass);


--
-- Name: modification_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modification_logs ALTER COLUMN id SET DEFAULT nextval('public.modification_logs_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: objection_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objection_actions ALTER COLUMN id SET DEFAULT nextval('public.objection_actions_id_seq'::regclass);


--
-- Name: organizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations ALTER COLUMN id SET DEFAULT nextval('public.organizations_id_seq'::regclass);


--
-- Name: package_loans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_loans ALTER COLUMN id SET DEFAULT nextval('public.package_loans_id_seq'::regclass);


--
-- Name: records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.records ALTER COLUMN id SET DEFAULT nextval('public.records_id_seq'::regclass);


--
-- Name: report_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_actions ALTER COLUMN id SET DEFAULT nextval('public.report_actions_id_seq'::regclass);


--
-- Name: report_deliveries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_deliveries ALTER COLUMN id SET DEFAULT nextval('public.report_deliveries_id_seq'::regclass);


--
-- Name: requested_tests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requested_tests ALTER COLUMN id SET DEFAULT nextval('public.requested_tests_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: sample_catalog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_catalog ALTER COLUMN id SET DEFAULT nextval('public.sample_catalog_id_seq'::regclass);


--
-- Name: sample_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_events ALTER COLUMN id SET DEFAULT nextval('public.sample_events_id_seq'::regclass);


--
-- Name: sample_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_groups ALTER COLUMN id SET DEFAULT nextval('public.sample_groups_id_seq'::regclass);


--
-- Name: template_field_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_field_mappings ALTER COLUMN id SET DEFAULT nextval('public.template_field_mappings_id_seq'::regclass);


--
-- Data for Name: attachments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.attachments (id, attachment_id, commission_no, package_no, task_no, sample_no, attachment_type, original_name, stored_name, relative_path, sha256, captured_at, uploader, description, is_original, parent_attachment_id, capture_source, checkpoint_code, checkpoint_label, device_id, evidence_status, server_captured_at, created_at) FROM stdin;
1	c70c9ba4c83747c8	WT20260817001	\N	BP20260817001-T01		photo	photo_1786950865541.jpg	BP20260817001-T01_152232.jpg	BP20260817001-T01/BP20260817001-T01_152232.jpg	6a163d941d8b16484ac8525724c0fb38d5be3663f58c4d62ad196bc046733131	\N	liuhong_test	\N	t	\N	file	MC_K_VALUE		\N	有效	2026-08-17 15:22:32.679386+08	2026-08-17 15:22:32.679386+08
3	c6e800376ddf49e7	WT20260817001	\N	BP20260817001-T01		photo	photo_1786950686432.jpg	BP20260817001-T01_152232_2.jpg	BP20260817001-T01/BP20260817001-T01_152232_2.jpg	8a3fee75d4b14f0e4b18adec893e2e08c7e0181517b9b7ddc65e95b95734ca31	\N	liuhong_test	\N	t	\N	file	TASK_CONFIRM		\N	有效	2026-08-17 15:22:32.681587+08	2026-08-17 15:22:32.681587+08
2	0b4b35f43f3c471c	WT20260817001	\N	BP20260817001-T01		photo	photo_1786950853863.jpg	BP20260817001-T01_152232_1.jpg	BP20260817001-T01/BP20260817001-T01_152232_1.jpg	e6b1508f8de706d1b4adfb8c6ea44b5d5324cf1603f53c286b18c1278f697236	\N	liuhong_test	\N	t	\N	file	MC_REPORT		\N	有效	2026-08-17 15:22:32.680652+08	2026-08-17 15:22:32.680652+08
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, entity_type, entity_id, actor, actor_name, actor_role, action, field_name, old_value, new_value, reason, client_time, device_id, session_token, snapshot_hash, previous_hash, entry_hash, created_at, commission_no) FROM stdin;
1	commission	WT20260817001	admin	赵衡	管理员	创建委托	\N	\N	\N	\N	\N	\N	\N	\N	0000000000000000000000000000000000000000000000000000000000000000	7ef272d944e5eff0dffa6a80bb2d529ff3fa49d817e70fb172e359bfc521a441	2026-08-17 15:07:43.813321+08	WT20260817001
2	sample_group	BP20260817001	admin	赵衡	管理员	创建样品组	\N	\N	\N	\N	\N	\N	\N	\N	7ef272d944e5eff0dffa6a80bb2d529ff3fa49d817e70fb172e359bfc521a441	09a66850e10fd7f70594159bc5b716e791bbe48c1a03ad921ff06c1d2bf2552f	2026-08-17 15:07:43.839839+08	WT20260817001
3	task_package	BAG-BP20260817001-P01	admin	赵衡	管理员	创建任务包	\N	\N	\N	\N	\N	\N	\N	\N	09a66850e10fd7f70594159bc5b716e791bbe48c1a03ad921ff06c1d2bf2552f	8d809befdc00b4fda34edc9bb427657e75c43466f8c6ba478bd17b66642d0422	2026-08-17 15:07:57.132317+08	WT20260817001
4	task_package	BAG-BP20260817001-P01	liuhong_test	刘红	实验员	接收任务包	\N	\N	\N	\N	\N	\N	\N	\N	8d809befdc00b4fda34edc9bb427657e75c43466f8c6ba478bd17b66642d0422	a01d4956c9afcf0046a00ba113c155d32af2122d0454c95b7c25d0e6b0647dfe	2026-08-17 15:09:11.057905+08	WT20260817001
5	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	a01d4956c9afcf0046a00ba113c155d32af2122d0454c95b7c25d0e6b0647dfe	3c4ee69080f7b2055df09f0d3c08ef6797320a9beafb82067f18455bd0ca680c	2026-08-17 15:11:28.617451+08	WT20260817001
6	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	3c4ee69080f7b2055df09f0d3c08ef6797320a9beafb82067f18455bd0ca680c	4f8df4e441841ccf2e1c54a564532a073002898397483cb341f58bf2ab8f02a0	2026-08-17 15:11:40.545267+08	WT20260817001
7	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	4f8df4e441841ccf2e1c54a564532a073002898397483cb341f58bf2ab8f02a0	684551f6fe9cbea7f3ac871976c026d39ad50b2c31d8d442eddb141bebc12c20	2026-08-17 15:13:22.908078+08	WT20260817001
8	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_form.em_source	说明书	检测报告		\N	\N	\N	\N	684551f6fe9cbea7f3ac871976c026d39ad50b2c31d8d442eddb141bebc12c20	6a4d0285c24aacc60151bda24aed8176bf988e1aec5c8bb091b4669f0fa61e15	2026-08-17 15:13:22.908983+08	WT20260817001
9	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_form.em_source_file		65432		\N	\N	\N	\N	6a4d0285c24aacc60151bda24aed8176bf988e1aec5c8bb091b4669f0fa61e15	ffc451f0bc6e3a3ff86e18e140ff0f4efc710c0a5f3cafa85493b3b6bb047e66	2026-08-17 15:13:22.9106+08	WT20260817001
10	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_form.orientation		金属面朝上、陶瓷面朝下		\N	\N	\N	\N	ffc451f0bc6e3a3ff86e18e140ff0f4efc710c0a5f3cafa85493b3b6bb047e66	d98bb7b7518708c989313a62f2614d9555815fb41107014b3085a73ba4feda44	2026-08-17 15:13:22.911493+08	WT20260817001
11	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_form.parallel_block_no	BGGL-B019	BPGL-B019		\N	\N	\N	\N	d98bb7b7518708c989313a62f2614d9555815fb41107014b3085a73ba4feda44	75d96289987960621324bbcdb97d03cdad416cc42866d533f50e220601b67dfb	2026-08-17 15:13:22.912564+08	WT20260817001
12	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_form.parallel_block_parallelism	0	4		\N	\N	\N	\N	75d96289987960621324bbcdb97d03cdad416cc42866d533f50e220601b67dfb	c6a9c99b63a05282a77ebf822d2322ff239f1d4a061ec7844aa8a5c54eb09285	2026-08-17 15:13:22.913896+08	WT20260817001
13	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	c6a9c99b63a05282a77ebf822d2322ff239f1d4a061ec7844aa8a5c54eb09285	3b73e54df5569288920837cfb8f74c2df8bc993ed492800073aa22122b1185fc	2026-08-17 15:15:23.244282+08	WT20260817001
14	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	report_summary	BP20260817001-S01：结合强度0MPa；BP20260817001-S02：结合强度0MPa	BP20260817001-S01：结合强度576MPa；BP20260817001-S02：结合强度576MPa		\N	\N	\N	\N	3b73e54df5569288920837cfb8f74c2df8bc993ed492800073aa22122b1185fc	84268a7e3e1b90c01c3782856f4c6a4e966ef05becbdad446593a267585ece11	2026-08-17 15:15:23.247626+08	WT20260817001
15	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	report_conclusion	不符合	符合		\N	\N	\N	\N	84268a7e3e1b90c01c3782856f4c6a4e966ef05becbdad446593a267585ece11	0d9b76d7c9e24c64d64a518708f07a8a4d065f693f25b3a50b390771ccc2bf15	2026-08-17 15:15:23.249855+08	WT20260817001
16	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].conclusion	不符合	符合		\N	\N	\N	\N	0d9b76d7c9e24c64d64a518708f07a8a4d065f693f25b3a50b390771ccc2bf15	966ac304d4ed615576c5c82c730abfc16e23d8a09fa0d899e31fce7624cd9ecc	2026-08-17 15:15:23.25097+08	WT20260817001
17	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].crack_position		22		\N	\N	\N	\N	966ac304d4ed615576c5c82c730abfc16e23d8a09fa0d899e31fce7624cd9ecc	d7bcae7d430b11c481db881f6854cf0dc12c1d07160029d199b032101242d6a6	2026-08-17 15:15:23.251964+08	WT20260817001
18	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm1	0	43		\N	\N	\N	\N	d7bcae7d430b11c481db881f6854cf0dc12c1d07160029d199b032101242d6a6	a6ff043532b77827fac32aef425f8f7f399a1b5aca894a6334ae12993e6c570c	2026-08-17 15:15:23.252929+08	WT20260817001
19	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm2	0	32		\N	\N	\N	\N	a6ff043532b77827fac32aef425f8f7f399a1b5aca894a6334ae12993e6c570c	ea63b910a5e6ab8d3f7da0e701873bc369ee7841df89734e1cbe3380f5e53563	2026-08-17 15:15:23.253845+08	WT20260817001
20	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm3	0	24		\N	\N	\N	\N	ea63b910a5e6ab8d3f7da0e701873bc369ee7841df89734e1cbe3380f5e53563	9408d000dbe323ac935967858c45bb129c5892fb8c1d02d55a7f5efbda9d733c	2026-08-17 15:15:23.254715+08	WT20260817001
21	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm_mean	0.0	33.0		\N	\N	\N	\N	9408d000dbe323ac935967858c45bb129c5892fb8c1d02d55a7f5efbda9d733c	6449aded1dff6e2e0860002c91d9a0a3ef9c6300af713e21f90aaf3d75d2cc5d	2026-08-17 15:15:23.255869+08	WT20260817001
22	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].em	0	24		\N	\N	\N	\N	6449aded1dff6e2e0860002c91d9a0a3ef9c6300af713e21f90aaf3d75d2cc5d	bcf76fffdf650ae0c97246e7a5aebb22fc1d5c1d71c627162ac466381016585d	2026-08-17 15:15:23.256801+08	WT20260817001
23	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].failure_mode		22		\N	\N	\N	\N	bcf76fffdf650ae0c97246e7a5aebb22fc1d5c1d71c627162ac466381016585d	f90789a968760a37e107d31f9a5d8173de437be771badc21fc916189a092d1df	2026-08-17 15:15:23.257542+08	WT20260817001
24	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].ffail	0	24		\N	\N	\N	\N	f90789a968760a37e107d31f9a5d8173de437be771badc21fc916189a092d1df	9370cc09b71b6005b4178ec5a85f12d85759cebb66442b19497c43f8de5288ea	2026-08-17 15:15:23.258541+08	WT20260817001
25	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].k	0	24		\N	\N	\N	\N	9370cc09b71b6005b4178ec5a85f12d85759cebb66442b19497c43f8de5288ea	155d43e358cec132140523c4b80af42139b4e575178c1b93fcbd0d85050c85ad	2026-08-17 15:15:23.259429+08	WT20260817001
26	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].tau	0.0	576.0		\N	\N	\N	\N	155d43e358cec132140523c4b80af42139b4e575178c1b93fcbd0d85050c85ad	c161476089a8c526519a6293649caad87d3d2262d6ebc835f492ea04f9c1b94b	2026-08-17 15:15:23.260365+08	WT20260817001
27	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[0].width	0	2		\N	\N	\N	\N	c161476089a8c526519a6293649caad87d3d2262d6ebc835f492ea04f9c1b94b	c488cd276fabdcdecb6d3c1304b15b2140b725771da9ee93fa679317e2b4a0f1	2026-08-17 15:15:23.261512+08	WT20260817001
28	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].conclusion	不符合	符合		\N	\N	\N	\N	c488cd276fabdcdecb6d3c1304b15b2140b725771da9ee93fa679317e2b4a0f1	be1dd09d6c1f4c0c61a3d0de298a5c1ce0b4f11a4ef6f254b9fda320964bee49	2026-08-17 15:15:23.262529+08	WT20260817001
29	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].crack_position		4		\N	\N	\N	\N	be1dd09d6c1f4c0c61a3d0de298a5c1ce0b4f11a4ef6f254b9fda320964bee49	73989bcb3cc6b93f2cacc972088f7007658c2ef520dc0c10e290437c02b42e71	2026-08-17 15:15:23.268956+08	WT20260817001
30	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].dm1	0	43		\N	\N	\N	\N	73989bcb3cc6b93f2cacc972088f7007658c2ef520dc0c10e290437c02b42e71	b399f2119a54bb9a8387e9b18b651d8790608c0c0433a01ac6e021fda2a9b2ec	2026-08-17 15:15:23.271183+08	WT20260817001
31	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].dm2	0	34		\N	\N	\N	\N	b399f2119a54bb9a8387e9b18b651d8790608c0c0433a01ac6e021fda2a9b2ec	54833152f189a8f64a92bc80c85ab44245ad4e20f64bd81c373b81f3c596e6d1	2026-08-17 15:15:23.272703+08	WT20260817001
32	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].dm3	0	4		\N	\N	\N	\N	54833152f189a8f64a92bc80c85ab44245ad4e20f64bd81c373b81f3c596e6d1	f915d2093a168613952c76b664e27279f582d22c6eacb73a13226b478c01c585	2026-08-17 15:15:23.273959+08	WT20260817001
33	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].dm_mean	0.0	27.0		\N	\N	\N	\N	f915d2093a168613952c76b664e27279f582d22c6eacb73a13226b478c01c585	cbb7782c31f6a333619e401525e235d9621f138feacc62df85752671500ca712	2026-08-17 15:15:23.275667+08	WT20260817001
34	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].em	0	2		\N	\N	\N	\N	cbb7782c31f6a333619e401525e235d9621f138feacc62df85752671500ca712	51afa626309f010d857a7b78fbda260105c7cf54a609d815ee91ba29dee4fc5b	2026-08-17 15:15:23.276863+08	WT20260817001
35	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].failure_mode		4		\N	\N	\N	\N	51afa626309f010d857a7b78fbda260105c7cf54a609d815ee91ba29dee4fc5b	c4cea0bc12d845b87918747ce831ebedcb74ba8edddba3bdcb4abe9997b84a10	2026-08-17 15:15:23.277811+08	WT20260817001
36	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].ffail	0	24		\N	\N	\N	\N	c4cea0bc12d845b87918747ce831ebedcb74ba8edddba3bdcb4abe9997b84a10	febf093eb70f87c46269871774e316ac356c7ca79ad1d8d71937978764f30a8f	2026-08-17 15:15:23.278834+08	WT20260817001
37	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].k	0	24		\N	\N	\N	\N	febf093eb70f87c46269871774e316ac356c7ca79ad1d8d71937978764f30a8f	4b3b3d9e2a1fcbddf6f97f91fd052bddc54de076d891eb9e2247ac3adb914d88	2026-08-17 15:15:23.279874+08	WT20260817001
38	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].tau	0.0	576.0		\N	\N	\N	\N	4b3b3d9e2a1fcbddf6f97f91fd052bddc54de076d891eb9e2247ac3adb914d88	261d0a80ffa6dc3af07ccfe16a4b5ae5465ff82a5cfc44560efc205b1c3ba666	2026-08-17 15:15:23.281135+08	WT20260817001
39	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_rows[1].width	0	43		\N	\N	\N	\N	261d0a80ffa6dc3af07ccfe16a4b5ae5465ff82a5cfc44560efc205b1c3ba666	0d17c118279be08c73073c3248673248bdfe8f4ac6fcc5cd92006250f075210d	2026-08-17 15:15:23.282249+08	WT20260817001
40	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0d17c118279be08c73073c3248673248bdfe8f4ac6fcc5cd92006250f075210d	6c614857b5a8d3f69714fd29e3fb8b2ee08ac0424c9b00fd1f24751c00ec3a6e	2026-08-17 15:15:59.143803+08	WT20260817001
41	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	6c614857b5a8d3f69714fd29e3fb8b2ee08ac0424c9b00fd1f24751c00ec3a6e	53b9b31eed55290d2cbe9ee953982a937e290a73d336faf0604c07378897cad8	2026-08-17 15:16:01.133049+08	WT20260817001
42	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	53b9b31eed55290d2cbe9ee953982a937e290a73d336faf0604c07378897cad8	113f2ade6d97f7f73835d18aa28b12273d7431c86951bb2d263c57abe52df6e7	2026-08-17 15:19:14.930943+08	WT20260817001
43	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	113f2ade6d97f7f73835d18aa28b12273d7431c86951bb2d263c57abe52df6e7	823918e8f28ea78a34d9db29c1bf6ccf5ec822de4af1cf8c9e3b9e99a785a664	2026-08-17 15:19:18.582586+08	WT20260817001
44	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	823918e8f28ea78a34d9db29c1bf6ccf5ec822de4af1cf8c9e3b9e99a785a664	0bcfa873c1856aa8d42fb61d0cee1a27af278a7cc17db2106b7fd1ad1754ac0e	2026-08-17 15:20:16.676763+08	WT20260817001
45	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0bcfa873c1856aa8d42fb61d0cee1a27af278a7cc17db2106b7fd1ad1754ac0e	d610e39f9fb4face49bc29d3f79e4d92c42c48941876ce2ed2f7dfccb09b779e	2026-08-17 15:20:22.589407+08	WT20260817001
46	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	d610e39f9fb4face49bc29d3f79e4d92c42c48941876ce2ed2f7dfccb09b779e	7dff544e8abaf070979e66e641131d2eb183d4af2541c4e92cf5986c526fb37d	2026-08-17 15:20:35.331505+08	WT20260817001
47	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	7dff544e8abaf070979e66e641131d2eb183d4af2541c4e92cf5986c526fb37d	9301c11cdc7babaac911c1da030f6345c85da00bada794de6de506d2b25da2eb	2026-08-17 15:22:03.634904+08	WT20260817001
48	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_overall_status	正常完成	存在异常		\N	\N	\N	\N	9301c11cdc7babaac911c1da030f6345c85da00bada794de6de506d2b25da2eb	0adf418e2e5a123994421dd1e5a25982a73a5a8e7bd1e0fddfdf8f212d1dd0bb	2026-08-17 15:22:03.635667+08	WT20260817001
49	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0adf418e2e5a123994421dd1e5a25982a73a5a8e7bd1e0fddfdf8f212d1dd0bb	d2a55ebc3b5a4ab50014a3607b881374037f1c581147eb2dd61c2321825b8362	2026-08-17 15:22:21.707481+08	WT20260817001
50	task	BP20260817001-T01	liuhong_test	刘红	实验员	标记实验结束	\N	\N	\N	\N	\N	\N	\N	\N	d2a55ebc3b5a4ab50014a3607b881374037f1c581147eb2dd61c2321825b8362	eb040bf3c702a92ad52388c3df8d85210c63ea3d71084580f6cc68a70dbe6942	2026-08-17 15:22:25.757413+08	WT20260817001
51	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	eb040bf3c702a92ad52388c3df8d85210c63ea3d71084580f6cc68a70dbe6942	0966a6c52fdbf9a94c862d4d7ec756afe19c377a026b2d1df42c8f85d03a438f	2026-08-17 15:22:26.823279+08	WT20260817001
52	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_overall_status	存在异常	正常完成		\N	\N	\N	\N	0966a6c52fdbf9a94c862d4d7ec756afe19c377a026b2d1df42c8f85d03a438f	57cd8397b952034081020cc2defbc366b667741770c441ad8241149e972980b9	2026-08-17 15:22:26.824183+08	WT20260817001
53	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_form.end_time		2026-08-17 15:22:25		\N	\N	\N	\N	57cd8397b952034081020cc2defbc366b667741770c441ad8241149e972980b9	5b5987c288322f941b69202fc799aa2e2fdccb229070e211bf2ddcab32504239	2026-08-17 15:22:26.825252+08	WT20260817001
54	record	BP20260817001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	5b5987c288322f941b69202fc799aa2e2fdccb229070e211bf2ddcab32504239	093a4c4e5f64d1e02b0f76344ed9fdfdff152f11d7b9c8aae0502824fc7cfa5e	2026-08-17 15:22:29.602455+08	WT20260817001
55	record	BP20260817001-T01	liuhong_test	刘红	实验员	提交复核	\N	\N	\N	\N	\N	\N	\N	\N	093a4c4e5f64d1e02b0f76344ed9fdfdff152f11d7b9c8aae0502824fc7cfa5e	043f6060a7e0c046ebdc871d822b74c368494ba3dbfc33e3baa957039b8033a4	2026-08-17 15:22:32.717063+08	WT20260817001
56	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	tester_self_check	否	是		\N	\N	\N	\N	043f6060a7e0c046ebdc871d822b74c368494ba3dbfc33e3baa957039b8033a4	5dac9be2ab2508c25fc5b3b0b295a253bf163b53172deb6e77c2a27be86ac697	2026-08-17 15:22:32.71799+08	WT20260817001
58	report	R20260817001-T01	system			自动生成报告初稿	\N	\N	\N	\N	\N	\N	\N	\N	ad25a94af92158e791a621375afd1e1aacefcd72b7cd5868a1d0b0f5c40c9f35	9476ad59310e1ae4167af183f9a4c8e95038e85082773d2de326129e926ea7fb	2026-08-17 15:32:39.794597+08	WT20260817001
57	record	BP20260817001-T01	liuhong_test	刘红	实验员	修改	_task_confirm_photo	blob:http://127.0.0.1:8000/f02f7ad4-0b90-4ac5-a4e0-f793b690b6b7	/api/v1/attachments/file/BP20260817001-T01/BP20260817001-T01_152232_2.jpg		\N	\N	\N	\N	5dac9be2ab2508c25fc5b3b0b295a253bf163b53172deb6e77c2a27be86ac697	ad25a94af92158e791a621375afd1e1aacefcd72b7cd5868a1d0b0f5c40c9f35	2026-08-17 15:22:32.719827+08	WT20260817001
61	report	R20260817001-T01	admin	赵衡	管理员	批准签发	status	待管理员签发	已发布	\N	\N	\N	\N	\N	b7f83efd69204eb904bb8b4605267e6a63fbacc37d58b033a0257fa50dc020e3	ae34c909fee627b90de607744204e0e368ea4011c5adb53a77b65d01c3772dbc	2026-08-17 15:37:34.927021+08	WT20260817001
59	record	BP20260817001-T01	lihongli_review	李红丽	复核员	复核通过	\N	\N	\N	\N	\N	\N	\N	\N	9476ad59310e1ae4167af183f9a4c8e95038e85082773d2de326129e926ea7fb	638fefc70cf562af6cfca89a986c058fba788f1efb0589a7eab7134b113f1526	2026-08-17 15:32:39.796294+08	WT20260817001
60	report	R20260817001-T01	quality	刘丽	质量负责人	质量审核通过	status	待质量审核	待管理员签发	\N	\N	\N	\N	\N	638fefc70cf562af6cfca89a986c058fba788f1efb0589a7eab7134b113f1526	b7f83efd69204eb904bb8b4605267e6a63fbacc37d58b033a0257fa50dc020e3	2026-08-17 15:37:08.730323+08	WT20260817001
71	experiment_method	I001	admin	赵衡	管理员	修改	standard	YY/T 1702-2020；GB/T 10610-2009	YY/T 1702-2020	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	ae34c909fee627b90de607744204e0e368ea4011c5adb53a77b65d01c3772dbc	49b5ca33612213727203fc3ae3c795edd334415bacb2081563983a1e00070afc	2026-08-18 10:47:44.246584+08	\N
72	experiment_method	I001	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	49b5ca33612213727203fc3ae3c795edd334415bacb2081563983a1e00070afc	6c66ef3be94cfee3701a00b343b9360c8957ada06fb3c42c743a1b15ec81b382	2026-08-18 10:47:44.277384+08	\N
73	experiment_standard	1	admin	赵衡	管理员	创建	standard	\N	GB 17168-2013《牙科学 固定和活动修复用金属材料》	为 I005 新增标准变体 1016	\N	\N	\N	\N	6c66ef3be94cfee3701a00b343b9360c8957ada06fb3c42c743a1b15ec81b382	2507cf8b83be5f0d72939cc416fd89147cb08dac33e1ac42d75dfb5a7c9d2ef3	2026-08-18 14:15:52.084746+08	\N
74	experiment_standard	1	admin	赵衡	管理员	修改	standard_name	热膨胀系数试验-金属材料	热膨胀系数试验-金属材料(改)	编辑标准变体 I005	\N	\N	\N	\N	2507cf8b83be5f0d72939cc416fd89147cb08dac33e1ac42d75dfb5a7c9d2ef3	7f952c4a0ea354c8ca5c0b3950a76f3278e5fb2c10e33c544895b680add96166	2026-08-18 14:15:52.154009+08	\N
75	experiment_standard	1	admin	赵衡	管理员	删除	standard	GB 17168-2013《牙科学 固定和活动修复用金属材料》	\N	删除标准变体 1016	\N	\N	\N	\N	7f952c4a0ea354c8ca5c0b3950a76f3278e5fb2c10e33c544895b680add96166	ed96e22c7e25d2f1f941e940f0db4b407e6b0d102d38e29569a5892a65fb8508	2026-08-18 14:15:52.160863+08	\N
76	experiment_standard	2	admin	赵衡	管理员	创建	standard	\N	ISO 22674-2016	为 I005 新增标准变体 1017	\N	\N	\N	\N	ed96e22c7e25d2f1f941e940f0db4b407e6b0d102d38e29569a5892a65fb8508	fd90b618782abc84636ebb2cf198c4f2089f6b8c8de56f16f8dac1dd35facba6	2026-08-18 14:15:52.169148+08	\N
77	experiment_standard	2	admin	赵衡	管理员	删除	standard	ISO 22674-2016	\N	删除标准变体 1017	\N	\N	\N	\N	fd90b618782abc84636ebb2cf198c4f2089f6b8c8de56f16f8dac1dd35facba6	0786bbd24ba0e0f4d6b83087bf8e66c0c8f3d2da6ed9d7dd8fd7da69700e7381	2026-08-18 14:15:52.17796+08	\N
78	experiment_standard	1	admin	赵衡	管理员	创建	standard	\N	GB 17168-2013《牙科学 固定和活动修复用金属材料》	为 I005 新增标准变体	\N	\N	\N	\N	0786bbd24ba0e0f4d6b83087bf8e66c0c8f3d2da6ed9d7dd8fd7da69700e7381	d1d2789c849c74491a9f4c5d4fafb8380560d8028b1f12f5f20867f34a4f4ae2	2026-08-18 14:32:08.109571+08	\N
79	experiment_standard	1	admin	赵衡	管理员	修改	standard	GB 17168-2013《牙科学 固定和活动修复用金属材料》	GB 17168-2013《牙科学 固定和活动修复用金属材料》(改)	编辑标准变体 I005	\N	\N	\N	\N	d1d2789c849c74491a9f4c5d4fafb8380560d8028b1f12f5f20867f34a4f4ae2	fcd0a72f669023acd1308f2e6c7ece38f0064ab45a594da323d51bddefea6d38	2026-08-18 14:32:08.189237+08	\N
80	experiment_standard	1	admin	赵衡	管理员	删除	standard	GB 17168-2013《牙科学 固定和活动修复用金属材料》(改)	\N	删除标准变体	\N	\N	\N	\N	fcd0a72f669023acd1308f2e6c7ece38f0064ab45a594da323d51bddefea6d38	4902c1a5d4560cd9bb208aa724f487dd835eeadd30099149a0929c80e8fd4c8f	2026-08-18 14:32:08.19412+08	\N
81	experiment_standard	2	admin	赵衡	管理员	创建	standard	\N	T/GDMDMA 0003-2020《定制式正畸矫治器》	为 I003 新增标准变体	\N	\N	\N	\N	4902c1a5d4560cd9bb208aa724f487dd835eeadd30099149a0929c80e8fd4c8f	389315be0abdfb2ecf2fdaa78bf9bed125d2bc97e70172c777d5b0e60f8c4d08	2026-08-18 14:34:53.939999+08	\N
82	experiment_standard	3	admin	赵衡	管理员	创建	standard	\N	GB 17168-2013《牙科学 固定和活动修复用金属材料》	为 I005 新增标准变体	\N	\N	\N	\N	389315be0abdfb2ecf2fdaa78bf9bed125d2bc97e70172c777d5b0e60f8c4d08	e81f6030d8e5d221f4e615f275c17f15e38a9be170ac6dd2381db911c2c563da	2026-08-18 14:35:17.356079+08	\N
83	experiment_standard	4	admin	赵衡	管理员	创建	standard	\N	ISO 22674:2022《牙科学 固定和活动修复体和矫治器用金属材料》；YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	为 I005 新增标准变体	\N	\N	\N	\N	e81f6030d8e5d221f4e615f275c17f15e38a9be170ac6dd2381db911c2c563da	1a5df08c466acb6bb9d057c9c6fb31593c392c2a4c137f046316090ba12cfb16	2026-08-18 14:35:36.425587+08	\N
84	experiment_method	I014	admin	赵衡	管理员	修改	method_code	YY 0710	YY/T1702-2020；YY/T 0528-2025	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	1a5df08c466acb6bb9d057c9c6fb31593c392c2a4c137f046316090ba12cfb16	93ec65e8811cc2c871b046acd0d4d8d66318bd35a7f834606a6ce7092743c3fe	2026-08-18 14:35:46.929018+08	\N
85	experiment_method	I014	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	93ec65e8811cc2c871b046acd0d4d8d66318bd35a7f834606a6ce7092743c3fe	c5d51e9d39cfbb78ba29dca85337479f11c860b1538e2d2d1bf93c30e8e487d6	2026-08-18 14:35:46.932322+08	\N
86	experiment_method	I014	admin	赵衡	管理员	修改	method_code	YY/T1702-2020；YY/T 0528-2025	YY/T1702-2020；YY/T 0528-2025；ISO 22674:2022	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	c5d51e9d39cfbb78ba29dca85337479f11c860b1538e2d2d1bf93c30e8e487d6	a201978f572ee409b46d7642b2b508e6e7d3f21a0c5cfd5c9d60d023079a7a32	2026-08-18 14:36:08.007914+08	\N
87	commission	WT20260818001	receiver	韩丹	样品管理员	创建委托	\N	\N	\N	\N	\N	\N	\N	\N	a201978f572ee409b46d7642b2b508e6e7d3f21a0c5cfd5c9d60d023079a7a32	916654c3d8a19ee8bef70a2e6d5ccddcb328c22399b2e5a3da8732b003858db2	2026-08-18 14:36:13.17003+08	WT20260818001
88	sample_group	BP20260818001	receiver	韩丹	样品管理员	创建样品组	\N	\N	\N	\N	\N	\N	\N	\N	916654c3d8a19ee8bef70a2e6d5ccddcb328c22399b2e5a3da8732b003858db2	11bc1e326e81dc1425fde70de2da9d56815a5c419a6f67df8289aeb8a0241d93	2026-08-18 14:36:13.240109+08	WT20260818001
89	task_package	BAG-BP20260818001-P01	receiver	韩丹	样品管理员	创建任务包	\N	\N	\N	\N	\N	\N	\N	\N	11bc1e326e81dc1425fde70de2da9d56815a5c419a6f67df8289aeb8a0241d93	5709a4a3662d3c5dfe4086da469092dbe9578495ec4975303a7edf29f5f528b6	2026-08-18 14:36:49.597513+08	WT20260818001
90	task_package	BAG-BP20260818001-P01	liuhong_test	刘红	实验员	接收任务包	\N	\N	\N	\N	\N	\N	\N	\N	5709a4a3662d3c5dfe4086da469092dbe9578495ec4975303a7edf29f5f528b6	70dd16274709d288eba24a9bfb1290d8d2cf48e8c2e41f1daa444bd5df168de5	2026-08-18 14:38:18.271789+08	WT20260818001
91	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	70dd16274709d288eba24a9bfb1290d8d2cf48e8c2e41f1daa444bd5df168de5	4029ee5eed0fb8f95c1111cf82df254c722ac9d8d3c6b5c25a2bde08a87c8677	2026-08-18 14:38:36.271141+08	WT20260818001
92	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	4029ee5eed0fb8f95c1111cf82df254c722ac9d8d3c6b5c25a2bde08a87c8677	78f36d92d4558deec79949bde92ec0f638c3a781d85b74c95a5af25ecc265e6b	2026-08-18 14:42:00.701518+08	WT20260818001
93	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	78f36d92d4558deec79949bde92ec0f638c3a781d85b74c95a5af25ecc265e6b	0da49c237581dcffb02e266d9bf8e27c9e8350fab991df97ce9d8c9553d81e71	2026-08-18 14:42:10.223128+08	WT20260818001
94	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0da49c237581dcffb02e266d9bf8e27c9e8350fab991df97ce9d8c9553d81e71	1964b0c85e680cd3d95e0ad6d8c0cfae92c8643bb1e3433cc830baafcf68eef8	2026-08-18 14:44:13.399453+08	WT20260818001
95	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	1964b0c85e680cd3d95e0ad6d8c0cfae92c8643bb1e3433cc830baafcf68eef8	cd8f253fbb30b9464d4bdd0c8097549f6cee55c6f9af03e76ede20c6a72c59d9	2026-08-18 14:44:23.036602+08	WT20260818001
98	experiment_method	I013	admin	赵衡	管理员	修改	method_code	YY/T 1702	YY/T 1702-2020	编辑检测项目，回写历史 2 条	\N	\N	\N	\N	bd234c7854b07dbf4b64219cfc25582181bd7762289d794dd0e73fd60b0614b7	9bfcd4f544548ce3807ca9f674db720a62c8d56049fb41f34ce8fbfb777b5cf4	2026-08-18 14:45:33.598026+08	\N
99	experiment_method	I013	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 2 条	\N	\N	\N	\N	9bfcd4f544548ce3807ca9f674db720a62c8d56049fb41f34ce8fbfb777b5cf4	95398dab0bdbf1ce1ea4489a24c02bf7fb2727c9d38ff659105a523166ddaebc	2026-08-18 14:45:33.601342+08	\N
100	experiment_method	I011	admin	赵衡	管理员	修改	method_code	YY/T 1936	YY/T 1936-2024	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	95398dab0bdbf1ce1ea4489a24c02bf7fb2727c9d38ff659105a523166ddaebc	6d4e7736a6a6f6cf221fb19a9791c3ab833981fa92f5432a62166873c2198c3f	2026-08-18 14:45:41.611036+08	\N
101	experiment_method	I011	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	6d4e7736a6a6f6cf221fb19a9791c3ab833981fa92f5432a62166873c2198c3f	153197b9cb06b937a9dafa8f050a450d72a1eaf113828aaf9fa8cd229eccae0e	2026-08-18 14:45:41.612946+08	\N
104	experiment_method	I009	admin	赵衡	管理员	修改	method_code	YY/T 1702	YY/T 1702-2020	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	9e991217eaf5e81ee255072831a0ee170ac8a26533c5300bb6ccd4a9f28d6041	7948b708cbbb6d97b3f91d1894caaffc87a9d9417d1a2044ecd39b19edd77525	2026-08-18 14:46:01.573844+08	\N
105	experiment_method	I009	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	7948b708cbbb6d97b3f91d1894caaffc87a9d9417d1a2044ecd39b19edd77525	f440dd28a2aa5370dc9b80c383a3c2b314b5da827fb12b29bbf415fc79c6f621	2026-08-18 14:46:01.576943+08	\N
108	experiment_method	I007	admin	赵衡	管理员	修改	method_code	YY/T 1702	YY/T 1702-2020	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	93b2760e6db7c9bec2c19cedcec0b0e93a5cababf6d4308f62ddedefe3202172	6990f95df2d4ebfcfdaf884fdef2ff4ec38958f20d65588cd94d723972171f77	2026-08-18 14:46:25.298665+08	\N
109	experiment_method	I007	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	6990f95df2d4ebfcfdaf884fdef2ff4ec38958f20d65588cd94d723972171f77	03b07a5b499c4346a6ebd53cc6659e974d989840c0d4b7b2344d38735c441ee4	2026-08-18 14:46:25.300283+08	\N
96	experiment_method	I012	admin	赵衡	管理员	修改	method_code	YY 0270.1	YY/T1937-2024	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	cd8f253fbb30b9464d4bdd0c8097549f6cee55c6f9af03e76ede20c6a72c59d9	dc6e39c9fd46cbbc88084670472cd6ae2f7b857228435aed71ed67dcfcb0dc17	2026-08-18 14:45:22.253202+08	\N
97	experiment_method	I012	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	dc6e39c9fd46cbbc88084670472cd6ae2f7b857228435aed71ed67dcfcb0dc17	bd234c7854b07dbf4b64219cfc25582181bd7762289d794dd0e73fd60b0614b7	2026-08-18 14:45:22.257613+08	\N
110	experiment_method	I006	admin	赵衡	管理员	修改	method_code	YY 0300	YY 0300-2009	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	03b07a5b499c4346a6ebd53cc6659e974d989840c0d4b7b2344d38735c441ee4	037c13179227bf959d02fb53203de2c82fd95eba018d206404f9921be9ba60a0	2026-08-18 14:46:35.124235+08	\N
111	experiment_method	I006	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	037c13179227bf959d02fb53203de2c82fd95eba018d206404f9921be9ba60a0	4a82f346e7bcdb53d5f1caf5ef90459c1c6d1bd963d8777b4ac31532388f0b94	2026-08-18 14:46:35.128961+08	\N
112	experiment_method	I005	admin	赵衡	管理员	修改	method_code	YY 0621.1	GB 30367-2013	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	4a82f346e7bcdb53d5f1caf5ef90459c1c6d1bd963d8777b4ac31532388f0b94	578df8c803de494726adfc48ad451ba0471ac5cb42d4eec5403a446fbb1e3e3d	2026-08-18 14:46:53.569287+08	\N
113	experiment_method	I005	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	578df8c803de494726adfc48ad451ba0471ac5cb42d4eec5403a446fbb1e3e3d	48d066828ba4b637dc702fa123ea92f34cc128c6028a5b2514c1270cf8beb548	2026-08-18 14:46:53.571825+08	\N
102	experiment_method	I010	admin	赵衡	管理员	修改	method_code	YY 0710	YY/T 0631-2008	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	153197b9cb06b937a9dafa8f050a450d72a1eaf113828aaf9fa8cd229eccae0e	d98f39d2715b4189a9e2d6f0cd590906bb4e92db92a95cc241dde3729a4a249e	2026-08-18 14:45:52.632672+08	\N
103	experiment_method	I010	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	d98f39d2715b4189a9e2d6f0cd590906bb4e92db92a95cc241dde3729a4a249e	9e991217eaf5e81ee255072831a0ee170ac8a26533c5300bb6ccd4a9f28d6041	2026-08-18 14:45:52.63448+08	\N
106	experiment_method	I008	admin	赵衡	管理员	修改	method_code	GB/T 4340.1	GB/T 4340.1-2024	编辑检测项目，回写历史 2 条	\N	\N	\N	\N	f440dd28a2aa5370dc9b80c383a3c2b314b5da827fb12b29bbf415fc79c6f621	d50080df0dd16c59bbf98e819043eadd666c7b3fb939adacb7d888047e1665cb	2026-08-18 14:46:14.601861+08	\N
107	experiment_method	I008	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 2 条	\N	\N	\N	\N	d50080df0dd16c59bbf98e819043eadd666c7b3fb939adacb7d888047e1665cb	93b2760e6db7c9bec2c19cedcec0b0e93a5cababf6d4308f62ddedefe3202172	2026-08-18 14:46:14.603812+08	\N
114	experiment_method	I004	admin	赵衡	管理员	修改	method_code	YY/T 1702	YY/T 1702-2020	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	48d066828ba4b637dc702fa123ea92f34cc128c6028a5b2514c1270cf8beb548	d621bbb806f329b699fdd3302046186ca88d423a235b52d6a5ec68a4111c63d5	2026-08-18 14:47:03.117753+08	\N
115	experiment_method	I004	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	d621bbb806f329b699fdd3302046186ca88d423a235b52d6a5ec68a4111c63d5	8cb1a8da770d1c6774bb24eeb0563ff4d6d7c3f242a3991c716653b71fc98b07	2026-08-18 14:47:03.121594+08	\N
116	experiment_method	I003	admin	赵衡	管理员	修改	method_code	GB 17168	YY/T1937-2024	编辑检测项目，回写历史 0 条	\N	\N	\N	\N	8cb1a8da770d1c6774bb24eeb0563ff4d6d7c3f242a3991c716653b71fc98b07	fd044d5ac02efb5892c0dfdf97fdfa92ca2725f5d56e50a799d58d46fe18445a	2026-08-18 14:47:32.365924+08	\N
117	experiment_method	I003	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 0 条	\N	\N	\N	\N	fd044d5ac02efb5892c0dfdf97fdfa92ca2725f5d56e50a799d58d46fe18445a	2b153066c8fd269ea72bea8188718697365d5ffa9db6c7d210b11630cf335abe	2026-08-18 14:47:32.372373+08	\N
118	experiment_method	I002	admin	赵衡	管理员	修改	method_code	YY 0621.1	YY 0621.1-2011	编辑检测项目，回写历史 2 条	\N	\N	\N	\N	2b153066c8fd269ea72bea8188718697365d5ffa9db6c7d210b11630cf335abe	b9f97c9f33fa7acecbba6108c0ec840ece7313573f924f47934caaff3ddc3718	2026-08-18 14:47:46.084996+08	\N
119	experiment_method	I002	admin	赵衡	管理员	修改	category	\N		编辑检测项目，回写历史 2 条	\N	\N	\N	\N	b9f97c9f33fa7acecbba6108c0ec840ece7313573f924f47934caaff3ddc3718	4c735046c6ce68fa25da4fbdd4ff6cf6259f0107650122336e3ff2e7bf14c7da	2026-08-18 14:47:46.089783+08	\N
120	experiment_method	I002	admin	赵衡	管理员	修改	method_code	YY 0621.1-2011	YY 0621.1-2016	编辑检测项目，回写历史 2 条	\N	\N	\N	\N	4c735046c6ce68fa25da4fbdd4ff6cf6259f0107650122336e3ff2e7bf14c7da	f67e941f0056c1759a9c13d4025cd45d02eefc7413d6f88259c02fb4c4a56a43	2026-08-18 14:47:53.17806+08	\N
121	experiment_method	I001	admin	赵衡	管理员	修改	method_code	YY/T 1702	YY/T 1702-2020	编辑检测项目，回写历史 2 条	\N	\N	\N	\N	f67e941f0056c1759a9c13d4025cd45d02eefc7413d6f88259c02fb4c4a56a43	72ce82f022d8068819b5157e3bedb76efc43b4425f1348fc91b76b4b4bffd688	2026-08-18 14:48:00.886108+08	\N
122	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	72ce82f022d8068819b5157e3bedb76efc43b4425f1348fc91b76b4b4bffd688	c979acf5b6de32588fbefd8adb1dd9421d8243537d888c7b2a6e2202044dd857	2026-08-18 14:51:32.403059+08	WT20260818001
123	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	c979acf5b6de32588fbefd8adb1dd9421d8243537d888c7b2a6e2202044dd857	dc32deaaa467429888a43f566a6a83d7517f567d8f91abf8897e6506b3486990	2026-08-18 14:51:34.092772+08	WT20260818001
124	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	dc32deaaa467429888a43f566a6a83d7517f567d8f91abf8897e6506b3486990	601d92f25cc9eb98ff54190fcc18cbeb4d160fe9eb3efbdcf8924ba967992520	2026-08-18 14:52:19.30491+08	WT20260818001
125	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	601d92f25cc9eb98ff54190fcc18cbeb4d160fe9eb3efbdcf8924ba967992520	ad5123411ae90e082ffb7624e2eddc84bbff0a0a7927a6b34c8016955f1b977a	2026-08-18 14:52:47.491855+08	WT20260818001
126	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	ad5123411ae90e082ffb7624e2eddc84bbff0a0a7927a6b34c8016955f1b977a	031ee95412dd9238b9db9f17e5e5c5b6af4b2c22ef5ab60b9ff2f199e3d507e6	2026-08-18 14:52:50.351155+08	WT20260818001
127	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	031ee95412dd9238b9db9f17e5e5c5b6af4b2c22ef5ab60b9ff2f199e3d507e6	94e175c7a71b0f17f52d1c887c0e0b1ef1443e741d60107509cbd72653241d58	2026-08-18 14:56:40.231789+08	WT20260818001
128	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	94e175c7a71b0f17f52d1c887c0e0b1ef1443e741d60107509cbd72653241d58	0ba30781c3edc38dca614ba09c1944c6fa06d3703863333c87d77e21725a553f	2026-08-18 14:57:32.555599+08	WT20260818001
129	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0ba30781c3edc38dca614ba09c1944c6fa06d3703863333c87d77e21725a553f	aa59a3bf9092e18a67977c8e57db57b2be826cbd7c0c7f8a690f328665576986	2026-08-18 14:57:37.747302+08	WT20260818001
130	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	aa59a3bf9092e18a67977c8e57db57b2be826cbd7c0c7f8a690f328665576986	9133ca5e51b7789979acf6fc8f35b26b5cac463025332ba6e61b1f8d66e0af7b	2026-08-18 14:57:43.168807+08	WT20260818001
131	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	9133ca5e51b7789979acf6fc8f35b26b5cac463025332ba6e61b1f8d66e0af7b	0e1634214c84c6fb5d93e57d7845375fd0fd41bd0f5d7daca7b8524f4f8fb26f	2026-08-18 14:57:52.661166+08	WT20260818001
132	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0e1634214c84c6fb5d93e57d7845375fd0fd41bd0f5d7daca7b8524f4f8fb26f	64b04c6ac6ee5fc21ece4d0d2dce91ee415873a21c807ab5dd459cd915ff4a71	2026-08-18 14:58:01.920464+08	WT20260818001
133	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	64b04c6ac6ee5fc21ece4d0d2dce91ee415873a21c807ab5dd459cd915ff4a71	a8062e417d8fabbc7063894cf9a75a7e6853ec36a2c31d827e7de22b12388a43	2026-08-18 14:58:05.857902+08	WT20260818001
134	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	a8062e417d8fabbc7063894cf9a75a7e6853ec36a2c31d827e7de22b12388a43	e200a972a5668f7abd48cbe738be36ddcf7abe1eda0af6b7478ca14e37a3199d	2026-08-18 14:58:22.644161+08	WT20260818001
135	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	e200a972a5668f7abd48cbe738be36ddcf7abe1eda0af6b7478ca14e37a3199d	cacd7f7c3b0d6f4ff303f0a4255421ddad7890a5145d76e041ea968a7f5bc6f2	2026-08-18 14:58:39.186919+08	WT20260818001
136	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	cacd7f7c3b0d6f4ff303f0a4255421ddad7890a5145d76e041ea968a7f5bc6f2	904299a74483917239cb9d4861defffb07011c75c318dd5aa6dab27e5531544e	2026-08-18 14:58:42.396406+08	WT20260818001
137	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	904299a74483917239cb9d4861defffb07011c75c318dd5aa6dab27e5531544e	f4710b81106a99b1fdf6fbab533555620f40e14773ebd891d3b879675a0c5ab0	2026-08-18 14:58:50.381683+08	WT20260818001
138	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	f4710b81106a99b1fdf6fbab533555620f40e14773ebd891d3b879675a0c5ab0	2e214d8dfe4c4cb17e7f42290c0d9c5a61f1b6d529cc2d889d2d08fbeee0f0d7	2026-08-18 14:58:57.640274+08	WT20260818001
139	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	2e214d8dfe4c4cb17e7f42290c0d9c5a61f1b6d529cc2d889d2d08fbeee0f0d7	69a647a911221213c6becac48fe3d925b4f2128aaa516995247ed6adb79b92df	2026-08-18 15:00:32.085431+08	WT20260818001
143	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	47305d6c264433174921b695c48ccae85e6a7498ffacf6e69b88c3e96794a053	5352dfb55323bd16de350a895b40a62b488e62939d16d1353cd579b4b4d7bae6	2026-08-18 15:04:34.520451+08	WT20260818001
146	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	3d123c79bab65460ae14b50c286b3fa803312e353621716e8a11103d28ccda88	3321f777cd5859f75e3c3ad69a9fdc516514ed1e85063bbd9224c4933a7a5525	2026-08-18 15:08:10.344859+08	WT20260818001
140	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	69a647a911221213c6becac48fe3d925b4f2128aaa516995247ed6adb79b92df	a24b3e2edeba2d4b0ddea6d737a536653621171972b5f4bd7b4e962d340ef981	2026-08-18 15:01:45.466301+08	WT20260818001
141	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	a24b3e2edeba2d4b0ddea6d737a536653621171972b5f4bd7b4e962d340ef981	0bc46f2b18039ed60e831a37cb7545b22d2f6bcf93def6d593570b7e7a3f698b	2026-08-18 15:02:54.247192+08	WT20260818001
145	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	4ba3333f1e098aa2150464eaa438f4e6008b8f3e701c07eadfc240bc392424e3	3d123c79bab65460ae14b50c286b3fa803312e353621716e8a11103d28ccda88	2026-08-18 15:04:40.684148+08	WT20260818001
142	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0bc46f2b18039ed60e831a37cb7545b22d2f6bcf93def6d593570b7e7a3f698b	47305d6c264433174921b695c48ccae85e6a7498ffacf6e69b88c3e96794a053	2026-08-18 15:03:11.30767+08	WT20260818001
144	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	5352dfb55323bd16de350a895b40a62b488e62939d16d1353cd579b4b4d7bae6	4ba3333f1e098aa2150464eaa438f4e6008b8f3e701c07eadfc240bc392424e3	2026-08-18 15:04:37.251526+08	WT20260818001
147	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	3321f777cd5859f75e3c3ad69a9fdc516514ed1e85063bbd9224c4933a7a5525	465ef6b6c45b5bf06dc7e2b1d9e9b6d194f5184b04a25f9b9bbc00762343f736	2026-08-18 15:19:53.353807+08	WT20260818001
148	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	465ef6b6c45b5bf06dc7e2b1d9e9b6d194f5184b04a25f9b9bbc00762343f736	f4d109d3d86b364af73d85e84cb5a109e08feb44df2e769de828b6a3999958a4	2026-08-18 15:20:09.410125+08	WT20260818001
149	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	f4d109d3d86b364af73d85e84cb5a109e08feb44df2e769de828b6a3999958a4	f84cb16a479d52a95f683b3e485332d13109ae206c4402b70a5c9402adc761fa	2026-08-18 15:20:27.689723+08	WT20260818001
150	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	f84cb16a479d52a95f683b3e485332d13109ae206c4402b70a5c9402adc761fa	c5d9044fe668d974128fd19deb80a4549073e64fe10da063c3fc0a70c7dc19e4	2026-08-18 15:21:26.731658+08	WT20260818001
151	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	c5d9044fe668d974128fd19deb80a4549073e64fe10da063c3fc0a70c7dc19e4	8d899d6f04b66bfdfbeceb93383e8a1dded375ce2f422ff69f15f75a4deedac5	2026-08-18 15:21:27.811455+08	WT20260818001
152	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	8d899d6f04b66bfdfbeceb93383e8a1dded375ce2f422ff69f15f75a4deedac5	e62b2c873451ab368c0efd55160102fabab1f8d5bcde0cd04a5c57c8cd1bdd3e	2026-08-18 15:21:34.427324+08	WT20260818001
153	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	e62b2c873451ab368c0efd55160102fabab1f8d5bcde0cd04a5c57c8cd1bdd3e	9b9971778e7e47098f12330ec18112ac0e22ccab3eabdeefec594b7111fa8071	2026-08-18 15:21:35.31579+08	WT20260818001
154	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	9b9971778e7e47098f12330ec18112ac0e22ccab3eabdeefec594b7111fa8071	855055d8a7d7b60f38cfb6642189a75680991805f2cb212ec8c4c9a284011d95	2026-08-18 15:21:36.922786+08	WT20260818001
155	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	855055d8a7d7b60f38cfb6642189a75680991805f2cb212ec8c4c9a284011d95	825939b86474fdd99f7c913f5a09c039b1c2b83a6c57816c4b1b37cf891d60a9	2026-08-18 15:24:09.133866+08	WT20260818001
156	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	825939b86474fdd99f7c913f5a09c039b1c2b83a6c57816c4b1b37cf891d60a9	280997e6f1803d80f50d7f31d8d3ebf67fc80720402b8873aa6a525c83853cc2	2026-08-18 15:24:19.884222+08	WT20260818001
157	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	280997e6f1803d80f50d7f31d8d3ebf67fc80720402b8873aa6a525c83853cc2	ee4ca9a9c20514c6fda98f17d99bbb377d64b36b2bfee457d664060f5de1703d	2026-08-18 15:24:30.893339+08	WT20260818001
158	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	ee4ca9a9c20514c6fda98f17d99bbb377d64b36b2bfee457d664060f5de1703d	50bd32f07cc137215ed40907b5e2610416b1f561f3d2ba63690492f9411a6434	2026-08-18 15:24:47.605072+08	WT20260818001
159	record	BP20260818001-T03	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	50bd32f07cc137215ed40907b5e2610416b1f561f3d2ba63690492f9411a6434	dafadac7835a395b963faf655736784fb98979baf1afc843065b385fb7b1efeb	2026-08-18 15:25:05.684579+08	WT20260818001
160	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	dafadac7835a395b963faf655736784fb98979baf1afc843065b385fb7b1efeb	47c1fc2519aed861e1f87bd42b951745e8715e97bb1e4f6245a1e0b066dbe647	2026-08-18 15:25:18.718153+08	WT20260818001
161	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	47c1fc2519aed861e1f87bd42b951745e8715e97bb1e4f6245a1e0b066dbe647	9a0bb46d0be3f984cee74c493b0f6a588b12bb6f71eb091cbd597db30fd3fddb	2026-08-18 15:27:53.404472+08	WT20260818001
162	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	9a0bb46d0be3f984cee74c493b0f6a588b12bb6f71eb091cbd597db30fd3fddb	112a1fa5fd02a1a28480a99cb48f9cdca90826f142f5ceffda04d29aae9cb232	2026-08-18 15:28:16.101027+08	WT20260818001
163	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	112a1fa5fd02a1a28480a99cb48f9cdca90826f142f5ceffda04d29aae9cb232	15a4db4aa292a997b29a82c0d01e549c2d1755e9c0aeda65f1cc74cd4ce38a24	2026-08-18 15:29:05.932891+08	WT20260818001
164	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	15a4db4aa292a997b29a82c0d01e549c2d1755e9c0aeda65f1cc74cd4ce38a24	15616128977f2b981cfea71461e13b622c65915490e6a30d207e950cf123abc8	2026-08-18 15:29:44.667972+08	WT20260818001
165	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	15616128977f2b981cfea71461e13b622c65915490e6a30d207e950cf123abc8	eb48378fef30230489969a98d67e6d018c967668139564a8cb2a891a01fbbebc	2026-08-18 15:29:47.133572+08	WT20260818001
166	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	eb48378fef30230489969a98d67e6d018c967668139564a8cb2a891a01fbbebc	5e1ed78b5203fbfbced0cd594f5b0ccd2ce217cfca8b69298aa320ffedbfa767	2026-08-18 15:29:50.735342+08	WT20260818001
167	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	5e1ed78b5203fbfbced0cd594f5b0ccd2ce217cfca8b69298aa320ffedbfa767	1e0df1009b462d83eaa06e7fd5f52b3d14d08d11976a370e5373b11527f682fe	2026-08-18 15:29:56.833325+08	WT20260818001
168	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	1e0df1009b462d83eaa06e7fd5f52b3d14d08d11976a370e5373b11527f682fe	b64885f608a32490268948977f8da17a0e00b5e4030e87cec4b7e3730860b746	2026-08-18 15:30:24.010772+08	WT20260818001
169	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	b64885f608a32490268948977f8da17a0e00b5e4030e87cec4b7e3730860b746	9cd02ec76081ccbb78b61fba320c0a0628c6158af8dcc169b238f9e075eb4b70	2026-08-18 15:30:38.250381+08	WT20260818001
170	record	BP20260818001-T02	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	9cd02ec76081ccbb78b61fba320c0a0628c6158af8dcc169b238f9e075eb4b70	c49383ee81934dd1fce6d2ac93f03b85a6538e68eb02b85a72275f370cf51e18	2026-08-18 15:30:40.013288+08	WT20260818001
171	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	c49383ee81934dd1fce6d2ac93f03b85a6538e68eb02b85a72275f370cf51e18	74737b883502570b74c045d277b445a2aecc6641232209b47d25a2bab58b86ba	2026-08-18 15:30:48.865592+08	WT20260818001
172	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	74737b883502570b74c045d277b445a2aecc6641232209b47d25a2bab58b86ba	3d6ad6583cd651fdd72dc66d977fb2d24afd80e8868e8daad7116abb73278b67	2026-08-18 15:30:50.543694+08	WT20260818001
173	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	3d6ad6583cd651fdd72dc66d977fb2d24afd80e8868e8daad7116abb73278b67	4a742da75a7b12567c72fd09e05c32f9e8386e5bcac45657b932f4423bb25b5e	2026-08-18 15:30:51.165513+08	WT20260818001
174	record	BP20260818001-T03	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	4a742da75a7b12567c72fd09e05c32f9e8386e5bcac45657b932f4423bb25b5e	611448a1a80a8a4c04929b687ea6133025345e76374a362028d93fc75ef4d0da	2026-08-18 15:31:10.82724+08	WT20260818001
175	record	BP20260818001-T03	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	611448a1a80a8a4c04929b687ea6133025345e76374a362028d93fc75ef4d0da	4e9950fd8553ac18ba50c524e8183c02bc5054de2e3f5ffc1f7d8bcc96bf2555	2026-08-18 15:31:32.175012+08	WT20260818001
176	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	4e9950fd8553ac18ba50c524e8183c02bc5054de2e3f5ffc1f7d8bcc96bf2555	c1418bf6802a605495f1c2d4049706a1f458e54d32ca400813e1e1f3d4b0b664	2026-08-18 15:31:35.780615+08	WT20260818001
177	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	c1418bf6802a605495f1c2d4049706a1f458e54d32ca400813e1e1f3d4b0b664	e93ffda03f960b86ef57f21445e472b889f16bd42ac88af471b8945a80d5736d	2026-08-18 15:31:38.319364+08	WT20260818001
178	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	e93ffda03f960b86ef57f21445e472b889f16bd42ac88af471b8945a80d5736d	bbb7d1165d603cc9c1f3e828c448c3634fb57df882e4c5305bdd913626000e91	2026-08-18 15:32:05.074118+08	WT20260818001
179	record	BP20260818001-T03	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	bbb7d1165d603cc9c1f3e828c448c3634fb57df882e4c5305bdd913626000e91	bd8272f278f152b24eca047eae3f3a649b04144b4c15ff6fdfebc7836caae0c7	2026-08-18 15:32:25.854612+08	WT20260818001
180	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	bd8272f278f152b24eca047eae3f3a649b04144b4c15ff6fdfebc7836caae0c7	b964a5b55b4d3ac4c9e732f05b526eb7b3b14562b07b029dd9e8c0873868b1f8	2026-08-18 15:32:51.386954+08	WT20260818001
181	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	b964a5b55b4d3ac4c9e732f05b526eb7b3b14562b07b029dd9e8c0873868b1f8	b89a06915ab9dd26c0af81fc8943134cc423f1f024dca088cdf8aaaf3733535f	2026-08-18 15:33:03.562732+08	WT20260818001
182	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	b89a06915ab9dd26c0af81fc8943134cc423f1f024dca088cdf8aaaf3733535f	ec865e0b18271e353cdd7044555773de0290bf51b01311c778a3f636eefc1d7b	2026-08-18 15:33:06.44976+08	WT20260818001
183	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	ec865e0b18271e353cdd7044555773de0290bf51b01311c778a3f636eefc1d7b	e40f50c356933b57e1e691f00a92df712f4cef6ed2da47ee98bdbe54fccffd6c	2026-08-18 15:33:19.671939+08	WT20260818001
184	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	e40f50c356933b57e1e691f00a92df712f4cef6ed2da47ee98bdbe54fccffd6c	d260d79b0f37681dd0651a1e7f7ba8c1f5d45d0033b8dccccdc69318e7d8ef76	2026-08-18 15:35:16.905389+08	WT20260818001
185	record	BP20260818001-T03	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	d260d79b0f37681dd0651a1e7f7ba8c1f5d45d0033b8dccccdc69318e7d8ef76	aac861cac79b98c072c0bc30cc269858eaccecf130ac8a6e8d1eb5c1aab78dee	2026-08-18 15:35:21.949239+08	WT20260818001
186	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	aac861cac79b98c072c0bc30cc269858eaccecf130ac8a6e8d1eb5c1aab78dee	9cc89cc389c2523ac4e82dbe385d41ec39df13dfcd9390dc194627e966a01e3a	2026-08-18 15:40:37.90689+08	WT20260818001
187	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	9cc89cc389c2523ac4e82dbe385d41ec39df13dfcd9390dc194627e966a01e3a	bf7c9062a427a1a37d534e4c3f5867f2ae6df685bc463430402362371e45a7a4	2026-08-18 15:40:40.986588+08	WT20260818001
188	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	bf7c9062a427a1a37d534e4c3f5867f2ae6df685bc463430402362371e45a7a4	7d1c6b6d8499837c5cb5bed1b9f8b561ef6d14df56b67903581b134760cf4b4c	2026-08-18 15:41:14.535249+08	WT20260818001
189	record	BP20260818001-T03	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	7d1c6b6d8499837c5cb5bed1b9f8b561ef6d14df56b67903581b134760cf4b4c	2b5d34c15f832f254319dc1be0dc52338968c5cc70fc45c96735b675710421ca	2026-08-18 15:44:53.855686+08	WT20260818001
190	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	2b5d34c15f832f254319dc1be0dc52338968c5cc70fc45c96735b675710421ca	d61e257b17ffaab933380b74a5e2afb20393f4f3d21f3d02543cc1babbc5345b	2026-08-18 15:46:03.140762+08	WT20260818001
191	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	d61e257b17ffaab933380b74a5e2afb20393f4f3d21f3d02543cc1babbc5345b	d205bcbf97100148cfb6b4d5f43a01d531d59ad4a142b2b40bde0175c741784d	2026-08-18 15:46:42.752949+08	WT20260818001
192	record	BP20260818001-T03	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	d205bcbf97100148cfb6b4d5f43a01d531d59ad4a142b2b40bde0175c741784d	0b1840c3b8f6b38969642f7762644f63db21bb2e4a2dd5e3bd3fa1dded2a3a60	2026-08-18 15:47:04.520687+08	WT20260818001
193	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0b1840c3b8f6b38969642f7762644f63db21bb2e4a2dd5e3bd3fa1dded2a3a60	99ef1d7c4f1a97180073d0926b6164234fcb69a45157bc9f8c0b2a8d53f5d002	2026-08-18 15:58:31.953781+08	WT20260818001
194	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	99ef1d7c4f1a97180073d0926b6164234fcb69a45157bc9f8c0b2a8d53f5d002	555534e10a7a887fb40f71ad3980301463e2c2ae4e56113612cd3ff2b2bf0077	2026-08-18 15:58:33.080466+08	WT20260818001
195	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	555534e10a7a887fb40f71ad3980301463e2c2ae4e56113612cd3ff2b2bf0077	fb862c63a837fa9cfd0f5d91d2c84dc04440b493d429665612bb4cd46d6b44f5	2026-08-18 16:02:43.128021+08	WT20260818001
196	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	fb862c63a837fa9cfd0f5d91d2c84dc04440b493d429665612bb4cd46d6b44f5	47b584efca6de27cdfb5aa24f8505b13fde1837eae28f484db778f6ce4faecfa	2026-08-19 10:18:25.100555+08	WT20260818001
197	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	47b584efca6de27cdfb5aa24f8505b13fde1837eae28f484db778f6ce4faecfa	4e5ae32a6da4399e2e2c24eee4467066795192a1519ab59369e33558787f7bbf	2026-08-19 10:20:19.224928+08	WT20260818001
198	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	4e5ae32a6da4399e2e2c24eee4467066795192a1519ab59369e33558787f7bbf	746fbc0226d2c61324a3db7ef1129047b42b62912260309119a0c50b09bdaea7	2026-08-19 10:20:52.737266+08	WT20260818001
199	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	746fbc0226d2c61324a3db7ef1129047b42b62912260309119a0c50b09bdaea7	e0c45839773249819e41d9d30151db0ec54aa5a7504db4539cdaec82d0e66754	2026-08-19 10:21:08.83299+08	WT20260818001
200	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	e0c45839773249819e41d9d30151db0ec54aa5a7504db4539cdaec82d0e66754	397ad40e25eb5a5696694670d5d67c10257633d3e471d817b68c21fe7b4c2598	2026-08-19 10:23:08.786031+08	WT20260818001
201	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	397ad40e25eb5a5696694670d5d67c10257633d3e471d817b68c21fe7b4c2598	9892b12a294d43ac17d7db3e840f181939f56f67872cb141188b73e503dcde69	2026-08-19 10:23:10.918012+08	WT20260818001
202	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	9892b12a294d43ac17d7db3e840f181939f56f67872cb141188b73e503dcde69	0f500eed65cc7c41d93c16b7f00ad600fd91aeb5689a30e1ce73cded271507d3	2026-08-19 10:27:01.683388+08	WT20260818001
203	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0f500eed65cc7c41d93c16b7f00ad600fd91aeb5689a30e1ce73cded271507d3	fcf1285871e9e9165505df24018a11cf13eb6d078b1446bf685b332b51f72970	2026-08-19 10:27:20.486926+08	WT20260818001
204	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	fcf1285871e9e9165505df24018a11cf13eb6d078b1446bf685b332b51f72970	324a93e534da12cd42ca1c726124808d4cb0ac734175299f148c5e300e565b65	2026-08-19 10:27:32.925637+08	WT20260818001
205	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	324a93e534da12cd42ca1c726124808d4cb0ac734175299f148c5e300e565b65	4566dd25626ec7d1e54b6080793c9db46e98577db81a53d4dec4ac5e6564ab94	2026-08-19 10:27:37.824399+08	WT20260818001
206	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	4566dd25626ec7d1e54b6080793c9db46e98577db81a53d4dec4ac5e6564ab94	fa2273a90e8dfd74128bed8c4007e7e353103c2de122aa10421a80b748073729	2026-08-19 10:29:45.139944+08	WT20260818001
207	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	fa2273a90e8dfd74128bed8c4007e7e353103c2de122aa10421a80b748073729	722f2448ba88160f80e421d741c80286bcd621aae502a8a5229866b49de1019b	2026-08-19 10:29:50.074529+08	WT20260818001
220	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0eb74194e392976b360f5c5923184585cf7df3a8a14834e3dd2a354d8aa0940e	5d1c31a345143ed6506ca95c40f50c9f75fe68f46bf7ecc86f0e37be7b2b0259	2026-08-19 10:32:04.544083+08	WT20260818001
224	task_package	BAG-BP20260819001-P01	admin	赵衡	管理员	创建任务包	\N	\N	\N	\N	\N	\N	\N	\N	6108217dc0266d61d4ca9cc916858807284eb6ff8cce2b63229acc5770b3c5a4	714e3a8a8e4dd693022880d6a902e6f2b1a2f3715105e2219053452ef64a2fba	2026-08-19 10:35:54.226121+08	WT20260819001
226	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	23ba9350517583c416e344ca8789526cd2a535836926cb0b6b555195a094aa94	dac36cc23c7427a454fba7b3be73b1ed405acb879e10e48aada2d2a0529bb99a	2026-08-19 10:36:44.399786+08	WT20260819001
228	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	04449aaf22c744b0e956cc352cb152561a921babb2fb29752d7f900613585ab6	711b0e8f6ee078e82855cc338b421d043be57d90b4a5f7387b61d827262d9232	2026-08-19 10:40:04.158981+08	WT20260819001
240	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	2fe3b63207c4ebf06b502c736a2309eb5ee8b98a9bff64981d4d3b09f7225a33	27f3e7a482343660e1afc675816e12aa53265197f251a286f113058697cfd9db	2026-08-19 10:49:29.168801+08	WT20260819001
241	record	BP20260819001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm2	0	\N		\N	\N	\N	\N	27f3e7a482343660e1afc675816e12aa53265197f251a286f113058697cfd9db	adb44620039392c793e1ffe27d3ac16a6c0019df0183fcf1afa15fc43de808eb	2026-08-19 10:49:29.169708+08	WT20260819001
242	record	BP20260819001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm_mean	0.0	\N		\N	\N	\N	\N	adb44620039392c793e1ffe27d3ac16a6c0019df0183fcf1afa15fc43de808eb	6a639481e95601bb5b0902cdb43c2c8f237893e11d56dbe4977ec2f00cc5630e	2026-08-19 10:49:29.172081+08	WT20260819001
208	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	722f2448ba88160f80e421d741c80286bcd621aae502a8a5229866b49de1019b	94c9bcce02fc2c15782d041247521254f43b060d54c13674168e1941639e863f	2026-08-19 10:30:58.501611+08	WT20260818001
209	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_form.evaluation_length	4	7.5		\N	\N	\N	\N	94c9bcce02fc2c15782d041247521254f43b060d54c13674168e1941639e863f	0f0a7dff229e66f920a5ed584bc6e64589b6150e9a4fecd9f35ba636aad4d275	2026-08-19 10:30:58.503235+08	WT20260818001
210	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_form.humidity_after	50	\N		\N	\N	\N	\N	0f0a7dff229e66f920a5ed584bc6e64589b6150e9a4fecd9f35ba636aad4d275	2ee02041ac7424e61a07095c1dccbaff769bdcc618ceb719548e2d84a32e5738	2026-08-19 10:30:58.512681+08	WT20260818001
211	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_form.humidity_before	50	\N		\N	\N	\N	\N	2ee02041ac7424e61a07095c1dccbaff769bdcc618ceb719548e2d84a32e5738	594f88db29b592744ff83002dd5aa4bd8efd1fa2e99451258e6ddc4083e7ea56	2026-08-19 10:30:58.513743+08	WT20260818001
212	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_form.humidity_compliance	符合	\N		\N	\N	\N	\N	594f88db29b592744ff83002dd5aa4bd8efd1fa2e99451258e6ddc4083e7ea56	c6978d33bed550e7b38babfd79e7d06d7849af7b7711426d3322329c107f33eb	2026-08-19 10:30:58.514676+08	WT20260818001
213	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_form.measuring_speed	0.5	1		\N	\N	\N	\N	c6978d33bed550e7b38babfd79e7d06d7849af7b7711426d3322329c107f33eb	57813c6f29113435f13bc0a4c8b177afe4fb7bba633e19273dd06af3b386fc82	2026-08-19 10:30:58.51551+08	WT20260818001
214	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_form.probe_condition		\N		\N	\N	\N	\N	57813c6f29113435f13bc0a4c8b177afe4fb7bba633e19273dd06af3b386fc82	bdb807a99d8bf6de09a7bdecd92296648af608cfdd9dc6c7a45899ef2e3fc22d	2026-08-19 10:30:58.516363+08	WT20260818001
215	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_form.repeat_check_2	0	\N		\N	\N	\N	\N	bdb807a99d8bf6de09a7bdecd92296648af608cfdd9dc6c7a45899ef2e3fc22d	1d5e8d2bb3565f7669f384b3cac9f89cff4e57fc71ed7cc8c27674f631b95118	2026-08-19 10:30:58.517002+08	WT20260818001
216	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_form.temperature_before	23	符合		\N	\N	\N	\N	1d5e8d2bb3565f7669f384b3cac9f89cff4e57fc71ed7cc8c27674f631b95118	8e8a495d394256774ce1ed5f5ae48c426fd78c26091cd61441c255113816c981	2026-08-19 10:30:58.517738+08	WT20260818001
217	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_form.temperature_compliance	符合	\N		\N	\N	\N	\N	8e8a495d394256774ce1ed5f5ae48c426fd78c26091cd61441c255113816c981	2f8a73c0cce063bb32aa613812611bbc3e4da59e07e025b8d11b30fa4e7d0b83	2026-08-19 10:30:58.518403+08	WT20260818001
218	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_rows[0].position		Z轴		\N	\N	\N	\N	2f8a73c0cce063bb32aa613812611bbc3e4da59e07e025b8d11b30fa4e7d0b83	99e7c5ecbedb074f53c7a06fcee7a4756f6d269a7f467d0e64716c5ae6de204a	2026-08-19 10:30:58.518985+08	WT20260818001
219	record	BP20260818001-T01	liuhong_test	刘红	实验员	修改	_rows[1].position		Z轴		\N	\N	\N	\N	99e7c5ecbedb074f53c7a06fcee7a4756f6d269a7f467d0e64716c5ae6de204a	0eb74194e392976b360f5c5923184585cf7df3a8a14834e3dd2a354d8aa0940e	2026-08-19 10:30:58.519649+08	WT20260818001
221	record	BP20260818001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	5d1c31a345143ed6506ca95c40f50c9f75fe68f46bf7ecc86f0e37be7b2b0259	2745803881d28aab19ae8007eb802880fe899c8f98c5d9bbb826a2a9872bb8f0	2026-08-19 10:32:12.874777+08	WT20260818001
222	commission	WT20260819001	admin	赵衡	管理员	创建委托	\N	\N	\N	\N	\N	\N	\N	\N	2745803881d28aab19ae8007eb802880fe899c8f98c5d9bbb826a2a9872bb8f0	9c96d87ca15e7dd691777207144c65c2d33a83e71700679098c90db4952936b1	2026-08-19 10:35:20.693185+08	WT20260819001
223	sample_group	BP20260819001	admin	赵衡	管理员	创建样品组	\N	\N	\N	\N	\N	\N	\N	\N	9c96d87ca15e7dd691777207144c65c2d33a83e71700679098c90db4952936b1	6108217dc0266d61d4ca9cc916858807284eb6ff8cce2b63229acc5770b3c5a4	2026-08-19 10:35:20.711972+08	WT20260819001
225	task_package	BAG-BP20260819001-P01	liuhong_test	刘红	实验员	接收任务包	\N	\N	\N	\N	\N	\N	\N	\N	714e3a8a8e4dd693022880d6a902e6f2b1a2f3715105e2219053452ef64a2fba	23ba9350517583c416e344ca8789526cd2a535836926cb0b6b555195a094aa94	2026-08-19 10:36:08.075698+08	WT20260819001
227	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	dac36cc23c7427a454fba7b3be73b1ed405acb879e10e48aada2d2a0529bb99a	04449aaf22c744b0e956cc352cb152561a921babb2fb29752d7f900613585ab6	2026-08-19 10:37:44.410414+08	WT20260819001
229	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	711b0e8f6ee078e82855cc338b421d043be57d90b4a5f7387b61d827262d9232	4b54e1b2a5253c6df1f7a389ed752a260200c80ed2ec576e56a03be88ae08886	2026-08-19 10:40:47.864169+08	WT20260819001
230	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	4b54e1b2a5253c6df1f7a389ed752a260200c80ed2ec576e56a03be88ae08886	fbe9ef9a7bb6e66c9077aadd06889fa3b65c13fb6d63739a82f2c6826913812c	2026-08-19 10:41:07.662618+08	WT20260819001
231	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	fbe9ef9a7bb6e66c9077aadd06889fa3b65c13fb6d63739a82f2c6826913812c	de4a255ceb6bc541dee4905819d5b003b8347b2c5d2063ca1ef34241eb9f04d1	2026-08-19 10:41:33.995211+08	WT20260819001
232	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	de4a255ceb6bc541dee4905819d5b003b8347b2c5d2063ca1ef34241eb9f04d1	120e3337a84db59b4796db98c9a86531fd1e8bd6c7f988fb7eb6223cb0524fa9	2026-08-19 10:41:34.200519+08	WT20260819001
233	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	120e3337a84db59b4796db98c9a86531fd1e8bd6c7f988fb7eb6223cb0524fa9	b3dd5906d76ad5aaed8262084748e14f5cdf32192eb7a733f60ee41646f49b06	2026-08-19 10:42:03.059239+08	WT20260819001
234	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	b3dd5906d76ad5aaed8262084748e14f5cdf32192eb7a733f60ee41646f49b06	30dd0cda7e84694feb33ae81642febf5d4c99f68600a19d043b856c11053a525	2026-08-19 10:46:48.154583+08	WT20260819001
235	record	BP20260819001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm2	0	\N		\N	\N	\N	\N	30dd0cda7e84694feb33ae81642febf5d4c99f68600a19d043b856c11053a525	7b9e1e81cef733701784fccb82820e0fa181901db228fa222595bdc878c732b4	2026-08-19 10:46:48.155474+08	WT20260819001
236	record	BP20260819001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm_mean	0.0	\N		\N	\N	\N	\N	7b9e1e81cef733701784fccb82820e0fa181901db228fa222595bdc878c732b4	235b5361687ad95429ddfa173169e3ad6dcdd11c441e605722188e2a35107c08	2026-08-19 10:46:48.160317+08	WT20260819001
237	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	235b5361687ad95429ddfa173169e3ad6dcdd11c441e605722188e2a35107c08	6056c138efb1b6cb96ecf28a018af86b71748fb127fb299dfc466af8eecb66b7	2026-08-19 10:46:52.448678+08	WT20260819001
238	record	BP20260819001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm2	\N	0		\N	\N	\N	\N	6056c138efb1b6cb96ecf28a018af86b71748fb127fb299dfc466af8eecb66b7	1721d602e843e5cd2add40a78faa5c2a4e39e056cbee5c3b4d52ad5b578f4a3d	2026-08-19 10:46:52.449658+08	WT20260819001
239	record	BP20260819001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm_mean	\N	0.0		\N	\N	\N	\N	1721d602e843e5cd2add40a78faa5c2a4e39e056cbee5c3b4d52ad5b578f4a3d	2fe3b63207c4ebf06b502c736a2309eb5ee8b98a9bff64981d4d3b09f7225a33	2026-08-19 10:46:52.45083+08	WT20260819001
243	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	6a639481e95601bb5b0902cdb43c2c8f237893e11d56dbe4977ec2f00cc5630e	3327e1b02cad60069500b32a5fbf880a4c51b0d0e2b2aa9ec7cfc2c685c56081	2026-08-19 10:49:31.775738+08	WT20260819001
244	record	BP20260819001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm2	\N	0		\N	\N	\N	\N	3327e1b02cad60069500b32a5fbf880a4c51b0d0e2b2aa9ec7cfc2c685c56081	1ce3b1f2aedeb2a213170f92a72f8ab4a813742624125aa2c268421fef493779	2026-08-19 10:49:31.776704+08	WT20260819001
245	record	BP20260819001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm_mean	\N	0.0		\N	\N	\N	\N	1ce3b1f2aedeb2a213170f92a72f8ab4a813742624125aa2c268421fef493779	d4ad28abcabde5c1bb35edae4f0ae179cd2538576ce5b1a1af1b7ab8a215a34c	2026-08-19 10:49:31.778034+08	WT20260819001
246	record	BP20260819001-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	d4ad28abcabde5c1bb35edae4f0ae179cd2538576ce5b1a1af1b7ab8a215a34c	30ef21dc4da8e2f3540b61fdb4085fba7edbae5d04281e2390900b87e6253b22	2026-08-19 10:50:39.268517+08	WT20260819001
247	record	BP20260819001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm2	0	\N		\N	\N	\N	\N	30ef21dc4da8e2f3540b61fdb4085fba7edbae5d04281e2390900b87e6253b22	6c58155bc896a11f618e279e778f2229bebbf6f72305c71d9bce815f9b4c4ffb	2026-08-19 10:50:39.269778+08	WT20260819001
248	record	BP20260819001-T01	liuhong_test	刘红	实验员	修改	_rows[0].dm_mean	0.0	\N		\N	\N	\N	\N	6c58155bc896a11f618e279e778f2229bebbf6f72305c71d9bce815f9b4c4ffb	ff5194c8765f39fe6cfbd09970a1a6e9ba0e972f6a2f20c74e7c746e33f6e462	2026-08-19 10:50:39.270985+08	WT20260819001
249	commission	WT20260819002	admin	赵衡	管理员	创建委托	\N	\N	\N	\N	\N	\N	\N	\N	ff5194c8765f39fe6cfbd09970a1a6e9ba0e972f6a2f20c74e7c746e33f6e462	c603f486501c4bcc580605a6e2559a6a4a95ac65fd025661f750379cec217d27	2026-08-19 10:53:16.501558+08	WT20260819002
250	sample_group	BP20260819002	admin	赵衡	管理员	创建样品组	\N	\N	\N	\N	\N	\N	\N	\N	c603f486501c4bcc580605a6e2559a6a4a95ac65fd025661f750379cec217d27	3bdbff8881a412c09a21efca5df3b5130c2ce625337bad94120df3de137cc8fd	2026-08-19 10:53:16.514452+08	WT20260819002
251	task_package	BAG-BP20260819002-P01	admin	赵衡	管理员	创建任务包	\N	\N	\N	\N	\N	\N	\N	\N	3bdbff8881a412c09a21efca5df3b5130c2ce625337bad94120df3de137cc8fd	0c38aa06a0e28d9bfe3d983882c2519f74772b1c8d9e69522d8d41139291a900	2026-08-19 10:53:44.997214+08	WT20260819002
252	commission	WT20260819003	admin	赵衡	管理员	创建委托	\N	\N	\N	\N	\N	\N	\N	\N	0c38aa06a0e28d9bfe3d983882c2519f74772b1c8d9e69522d8d41139291a900	242cfb4c2463a16612461c0036163bcf3d2b84bc762f29d5be93aea87d507e7b	2026-08-19 10:57:27.511171+08	WT20260819003
253	sample_group	BP20260819003	admin	赵衡	管理员	创建样品组	\N	\N	\N	\N	\N	\N	\N	\N	242cfb4c2463a16612461c0036163bcf3d2b84bc762f29d5be93aea87d507e7b	4387d65590660e30d4ed6baabbfb2c46b39752723b2084730a201754d6c04b83	2026-08-19 10:57:27.522332+08	WT20260819003
254	task_package	BAG-BP20260819003-P01	admin	赵衡	管理员	创建任务包	\N	\N	\N	\N	\N	\N	\N	\N	4387d65590660e30d4ed6baabbfb2c46b39752723b2084730a201754d6c04b83	22ebec2b736b3d4fc4cf071050e9a15f9122e0ed437d4013bfae1ca3761b6b8e	2026-08-19 10:58:43.032687+08	WT20260819003
255	commission	WT20260819004	admin	赵衡	管理员	创建委托	\N	\N	\N	\N	\N	\N	\N	\N	22ebec2b736b3d4fc4cf071050e9a15f9122e0ed437d4013bfae1ca3761b6b8e	c5865da55466111414fd070f5dfc400cef1ce31dc40a386b1d57bfd21bd61032	2026-08-19 11:00:02.251447+08	WT20260819004
256	sample_group	BP20260819004	admin	赵衡	管理员	创建样品组	\N	\N	\N	\N	\N	\N	\N	\N	c5865da55466111414fd070f5dfc400cef1ce31dc40a386b1d57bfd21bd61032	a56ed168d2da00039bf50fbf369298aeb7a29c132c68e133d5bdff852f06d52b	2026-08-19 11:00:02.260782+08	WT20260819004
257	sample_group	BP20260819005	admin	赵衡	管理员	创建样品组	\N	\N	\N	\N	\N	\N	\N	\N	a56ed168d2da00039bf50fbf369298aeb7a29c132c68e133d5bdff852f06d52b	75dcf9e4b3918427742b19890c2390337e8be1ad931103266b34e136fd5cf116	2026-08-19 11:00:02.27205+08	WT20260819004
258	task_package	BAG-BP20260819004-P01	admin	赵衡	管理员	创建任务包	\N	\N	\N	\N	\N	\N	\N	\N	75dcf9e4b3918427742b19890c2390337e8be1ad931103266b34e136fd5cf116	b470622e104bc1489b0e8af523835d9a61874c693dcb44e35afd5e69bf44ca62	2026-08-19 11:00:17.842017+08	WT20260819004
259	task_package	BAG-BP20260819005-P01	admin	赵衡	管理员	创建任务包	\N	\N	\N	\N	\N	\N	\N	\N	b470622e104bc1489b0e8af523835d9a61874c693dcb44e35afd5e69bf44ca62	da147c6ada701143d4c466737e8a31a7a1a9cc6513b03cb824f1855584e1f846	2026-08-19 11:00:32.481156+08	WT20260819004
260	task_package	BAG-BP20260819005-P01	liuhong_test	刘红	实验员	接收任务包	\N	\N	\N	\N	\N	\N	\N	\N	da147c6ada701143d4c466737e8a31a7a1a9cc6513b03cb824f1855584e1f846	28217774e1a64183ac5a030a546c41cdb628ade5de9a468838d55c3244ed97b5	2026-08-19 11:01:59.109527+08	WT20260819004
261	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	28217774e1a64183ac5a030a546c41cdb628ade5de9a468838d55c3244ed97b5	6a4e6dc9ad5cc536db0c4fd6c7bf2fc1c14849dc50519676b43fa72c6f87567f	2026-08-19 11:02:29.587417+08	WT20260819004
262	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	6a4e6dc9ad5cc536db0c4fd6c7bf2fc1c14849dc50519676b43fa72c6f87567f	e6cd6000ec578a59dc5d74fa5e3eda9dd9dfd041fe7fb228946d1ec21b40947b	2026-08-19 11:03:18.358213+08	WT20260819004
263	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	e6cd6000ec578a59dc5d74fa5e3eda9dd9dfd041fe7fb228946d1ec21b40947b	007ac02d5ead8adf433f4531653710951d60f1152a8ee520f9cd27b809f6ec1c	2026-08-19 11:05:20.190614+08	WT20260819004
264	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	007ac02d5ead8adf433f4531653710951d60f1152a8ee520f9cd27b809f6ec1c	937298844c81bd61671d60645a8a944724d4891b2b16ba91ad8651d3915140c6	2026-08-19 11:05:27.364251+08	WT20260819004
265	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	937298844c81bd61671d60645a8a944724d4891b2b16ba91ad8651d3915140c6	27f80b27e58fec30f4a81ceec418fea24529e113b6b123dbb74526f7bd045557	2026-08-19 11:06:28.186376+08	WT20260819004
266	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	27f80b27e58fec30f4a81ceec418fea24529e113b6b123dbb74526f7bd045557	b036dd50af5494543ed01a13e381e802bcfdc93c340d5190edfafcf71be7aeed	2026-08-19 11:07:09.818252+08	WT20260819004
267	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	b036dd50af5494543ed01a13e381e802bcfdc93c340d5190edfafcf71be7aeed	a74f352260233ea1ba935cdffcaa97dff15c04106ec63c64884456df53789ba6	2026-08-19 11:07:30.052847+08	WT20260819004
268	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.exposure_time	110	71		\N	\N	\N	\N	a74f352260233ea1ba935cdffcaa97dff15c04106ec63c64884456df53789ba6	50cc7122a7cb58845165b26bd5af25968c98e9fa3ca288d4220e733c809375ba	2026-08-19 11:07:30.053959+08	WT20260819004
269	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.focus_mode	L	S		\N	\N	\N	\N	50cc7122a7cb58845165b26bd5af25968c98e9fa3ca288d4220e733c809375ba	00d44bbfe24203be1204cb70a2de2d55f9f6166be6d6d716da18fa23d9e0be54	2026-08-19 11:07:30.055045+08	WT20260819004
270	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.mas	6.3	1		\N	\N	\N	\N	00d44bbfe24203be1204cb70a2de2d55f9f6166be6d6d716da18fa23d9e0be54	03d3f112861bf1afaa069d6d2d06ca52b06ecc9de293e3daf4e520cc3a28175d	2026-08-19 11:07:30.055957+08	WT20260819004
271	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.tube_current	56	14		\N	\N	\N	\N	03d3f112861bf1afaa069d6d2d06ca52b06ecc9de293e3daf4e520cc3a28175d	bbd349b08a0ace431be05ce40e9eff6a96c4e01668a9a3a6472df5d17ed3ccea	2026-08-19 11:07:30.056817+08	WT20260819004
272	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.tube_voltage	75	72		\N	\N	\N	\N	bbd349b08a0ace431be05ce40e9eff6a96c4e01668a9a3a6472df5d17ed3ccea	6f5b54776a2e503086b6c8c3770fdccd86f52c7515e50f869508dc2be0c47106	2026-08-19 11:07:30.057579+08	WT20260819004
273	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	6f5b54776a2e503086b6c8c3770fdccd86f52c7515e50f869508dc2be0c47106	7f2441b9dde74594314f81b34fc494ae596d4c5574a25d4288c7a5d1e001217a	2026-08-19 11:07:43.324315+08	WT20260819004
274	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	7f2441b9dde74594314f81b34fc494ae596d4c5574a25d4288c7a5d1e001217a	84ae6d6845521e5c9e11df6be7a35fcca344657f6b39aaaf5bf80222575ef3e8	2026-08-19 11:11:37.745705+08	WT20260819004
276	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	4aac4726700f7696279fc552eb83e9dc120b6de892ee85cda31f779695f73754	ba76045bc6d37e2b6846f66e89c12caf8d96733c6206b40c26fca9b5719b37d2	2026-08-19 11:28:33.6141+08	WT20260819004
277	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_1	0	1.2		\N	\N	\N	\N	ba76045bc6d37e2b6846f66e89c12caf8d96733c6206b40c26fca9b5719b37d2	99a36f9685fe044235b78516e26259fb00e088b0d3a142c51b259770ef755bf4	2026-08-19 11:28:33.615187+08	WT20260819004
278	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_2	0	1.11		\N	\N	\N	\N	99a36f9685fe044235b78516e26259fb00e088b0d3a142c51b259770ef755bf4	deca19f38d1b9e02a2bbc71b5af05e1f8a5f9fe385cf9a4e1e16eb353f004004	2026-08-19 11:28:33.616807+08	WT20260819004
279	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_3	0	1.21		\N	\N	\N	\N	deca19f38d1b9e02a2bbc71b5af05e1f8a5f9fe385cf9a4e1e16eb353f004004	7db63627a5b6c760ace249724bbc528afce2448c244b2990c1d3f89d436016d6	2026-08-19 11:28:33.617661+08	WT20260819004
280	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_meter_no		BPGL-A029;BPGL-B005		\N	\N	\N	\N	7db63627a5b6c760ace249724bbc528afce2448c244b2990c1d3f89d436016d6	5ef92af6eb18dba36f7e749380ac8d9904b53c9e30dcfd6b3e570a871a38d0ee	2026-08-19 11:28:33.618363+08	WT20260819004
281	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.humidity_after	50	\N		\N	\N	\N	\N	5ef92af6eb18dba36f7e749380ac8d9904b53c9e30dcfd6b3e570a871a38d0ee	9987ae388475a862974f05df7f52abeebfaa389788fb9d16d8ee44eea9ac27d2	2026-08-19 11:28:33.6191+08	WT20260819004
282	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_07_2	0	1		\N	\N	\N	\N	9987ae388475a862974f05df7f52abeebfaa389788fb9d16d8ee44eea9ac27d2	626e00b6f6282a728b7bae2ab2e8c3a5b6d9bd1573cc58eeea3e96face0be8e9	2026-08-19 11:28:33.619994+08	WT20260819004
283	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_08_2	0	-1		\N	\N	\N	\N	626e00b6f6282a728b7bae2ab2e8c3a5b6d9bd1573cc58eeea3e96face0be8e9	3bb68a137f8b367fbcf448fe9b94a082cf7772255bd74f14a5e1c5c871ffca2b	2026-08-19 11:28:33.620584+08	WT20260819004
284	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_09_2	0	-1		\N	\N	\N	\N	3bb68a137f8b367fbcf448fe9b94a082cf7772255bd74f14a5e1c5c871ffca2b	635f137d44db955fd951b8c451a44f5c3f74f9a7550325c4ad3a64f1b250c853	2026-08-19 11:28:33.621266+08	WT20260819004
285	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_no		BPGL-B016;BPGL-B017;BPGL-B018		\N	\N	\N	\N	635f137d44db955fd951b8c451a44f5c3f74f9a7550325c4ad3a64f1b250c853	7c2f7be157a8cc29010f40aa0f6b7e18be4c129d1594cd54ae0c2cdd0eec779f	2026-08-19 11:28:33.621914+08	WT20260819004
286	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.panel_no		BPGL-B024		\N	\N	\N	\N	7c2f7be157a8cc29010f40aa0f6b7e18be4c129d1594cd54ae0c2cdd0eec779f	7077b7f70457f7c539f836e097cfee34a02d89d4eeaa24e8d82fd40f699f1d41	2026-08-19 11:28:33.622518+08	WT20260819004
287	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.xray_model		BPGL-A032		\N	\N	\N	\N	7077b7f70457f7c539f836e097cfee34a02d89d4eeaa24e8d82fd40f699f1d41	fe19432fd84bbf8e7d96896b3dd9059815cbd26bfd311cbdfccdfb606920332f	2026-08-19 11:28:33.62307+08	WT20260819004
303	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	95de849536f5ee02828c37dc7bd4186e0ca54f31f9f1785d3db231d71ad975db	0be2e6f3966c2d63f2867b6a7d6ccc43ad1d842326d549284d95bd78914f993b	2026-08-19 11:28:59.967587+08	WT20260819004
304	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	0be2e6f3966c2d63f2867b6a7d6ccc43ad1d842326d549284d95bd78914f993b	0737c2daea23d92a56174fb232224ba131b3b970119a6a16ede683933f235b58	2026-08-19 11:29:14.847259+08	WT20260819004
305	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	report_summary	BP20260819005-S01：ROI平均灰度0.4	BP20260819005-S01：ROI平均灰度0		\N	\N	\N	\N	0737c2daea23d92a56174fb232224ba131b3b970119a6a16ede683933f235b58	d1bd2e6dcd6569e4752dc379fdb210c8318d986111c85fe9959675d7308eb0c8	2026-08-19 11:29:14.848335+08	WT20260819004
306	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_1	0	1.2		\N	\N	\N	\N	d1bd2e6dcd6569e4752dc379fdb210c8318d986111c85fe9959675d7308eb0c8	ae359bc9358a885f82f616b2206f81c4227dbc85f7069dde03d2aebf95871bb7	2026-08-19 11:29:14.849653+08	WT20260819004
307	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_2	0	1.11		\N	\N	\N	\N	ae359bc9358a885f82f616b2206f81c4227dbc85f7069dde03d2aebf95871bb7	278edd8b29b4db3459f63614ea569387161861cf6793e4fe93d9056fd0fc9431	2026-08-19 11:29:14.850827+08	WT20260819004
308	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_3	0	1.21		\N	\N	\N	\N	278edd8b29b4db3459f63614ea569387161861cf6793e4fe93d9056fd0fc9431	40c99bc32a34e279b52b635b16f7bc2997a5f3e53862c9becf8e7d407a854cee	2026-08-19 11:29:14.851743+08	WT20260819004
309	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_07_2	0	1		\N	\N	\N	\N	40c99bc32a34e279b52b635b16f7bc2997a5f3e53862c9becf8e7d407a854cee	d395b32c7d47381a76ee6a6c961fffccdf4082f297d07a9bae13cccc1c09618c	2026-08-19 11:29:14.85267+08	WT20260819004
310	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_08_2	0	-1		\N	\N	\N	\N	d395b32c7d47381a76ee6a6c961fffccdf4082f297d07a9bae13cccc1c09618c	e85a36694d13d214be2f9e77ee15c1ea4af3145e49de0ebcff6060fd2bf6b27f	2026-08-19 11:29:14.85355+08	WT20260819004
311	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_09_2	0	-1		\N	\N	\N	\N	e85a36694d13d214be2f9e77ee15c1ea4af3145e49de0ebcff6060fd2bf6b27f	90ecc285b5046cb68e05230b407219aa0ed759eee2bcabd991c4c900ee75e463	2026-08-19 11:29:14.854436+08	WT20260819004
312	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1	1.21	0.0		\N	\N	\N	\N	90ecc285b5046cb68e05230b407219aa0ed759eee2bcabd991c4c900ee75e463	a901055ebd84d50c3bcb2ada20efcafc44acd65812d11e005cb6b9e423f5df12	2026-08-19 11:29:14.855319+08	WT20260819004
313	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1_reading1	1.08	0		\N	\N	\N	\N	a901055ebd84d50c3bcb2ada20efcafc44acd65812d11e005cb6b9e423f5df12	dba9da916b841c6798c577bccebd0e3369ef3dfb3ba880a64d9b09f548595e34	2026-08-19 11:29:14.856296+08	WT20260819004
314	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1_reading2	1.31	0		\N	\N	\N	\N	dba9da916b841c6798c577bccebd0e3369ef3dfb3ba880a64d9b09f548595e34	5cbe96bacd7a2c98a72027bba1c89c894bdb002321784308a8c90c0f8d2a1d71	2026-08-19 11:29:14.85696+08	WT20260819004
315	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1_reading3	1.24	0		\N	\N	\N	\N	5cbe96bacd7a2c98a72027bba1c89c894bdb002321784308a8c90c0f8d2a1d71	45c6258a763fb5f2e7fc5065616bee75980d7ab93070dc642ecc921e403ea0d0	2026-08-19 11:29:14.85777+08	WT20260819004
316	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi_mean	0.4	0.0		\N	\N	\N	\N	45c6258a763fb5f2e7fc5065616bee75980d7ab93070dc642ecc921e403ea0d0	f78b26643102765977cfcb991411c6ae095614cb025b63bfa424b3fdfe2bccf9	2026-08-19 11:29:14.858419+08	WT20260819004
275	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	84ae6d6845521e5c9e11df6be7a35fcca344657f6b39aaaf5bf80222575ef3e8	4aac4726700f7696279fc552eb83e9dc120b6de892ee85cda31f779695f73754	2026-08-19 11:11:45.113234+08	WT20260819004
288	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	fe19432fd84bbf8e7d96896b3dd9059815cbd26bfd311cbdfccdfb606920332f	e3e87215454338bac921611bbd12a1088d38cd6f73911379d43905fcb53f9815	2026-08-19 11:28:40.783393+08	WT20260819004
289	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	e3e87215454338bac921611bbd12a1088d38cd6f73911379d43905fcb53f9815	64ae5ba68d8035c1596782c33c77d9138251f3b928457a1f86fdb32aa147b075	2026-08-19 11:28:48.972622+08	WT20260819004
290	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	report_summary	BP20260819005-S01：ROI平均灰度0	BP20260819005-S01：ROI平均灰度0.4		\N	\N	\N	\N	64ae5ba68d8035c1596782c33c77d9138251f3b928457a1f86fdb32aa147b075	7a5ca1082b967fbc331d3a1112bd12b91b399e656637c2e5ca68b47aafd1bfe4	2026-08-19 11:28:48.974319+08	WT20260819004
291	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_1	1.2	0		\N	\N	\N	\N	7a5ca1082b967fbc331d3a1112bd12b91b399e656637c2e5ca68b47aafd1bfe4	75c975c31f15b1c2ec88222357344aeb6ee67a6ab4d5eee2c4e004cac59b1fb7	2026-08-19 11:28:48.976477+08	WT20260819004
292	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_2	1.11	0		\N	\N	\N	\N	75c975c31f15b1c2ec88222357344aeb6ee67a6ab4d5eee2c4e004cac59b1fb7	bd3f7f349c0ae4531101cc5921cd808c0b30dcac0fa6c8f21a42dba7b4b5dc6b	2026-08-19 11:28:48.978335+08	WT20260819004
293	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_3	1.21	0		\N	\N	\N	\N	bd3f7f349c0ae4531101cc5921cd808c0b30dcac0fa6c8f21a42dba7b4b5dc6b	bef73edd7786c54f9b08623425076afb752319fd6e913f7c22e648d168067660	2026-08-19 11:28:48.979865+08	WT20260819004
294	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_07_2	1	0		\N	\N	\N	\N	bef73edd7786c54f9b08623425076afb752319fd6e913f7c22e648d168067660	696526775303f8c713d7cb6a99cd635e96076720e6534d45524c46cbe8b6d833	2026-08-19 11:28:48.981042+08	WT20260819004
295	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_08_2	-1	0		\N	\N	\N	\N	696526775303f8c713d7cb6a99cd635e96076720e6534d45524c46cbe8b6d833	dc872d9163b0ce3fab3ac05134fe322aeaefabdf483678b1250e67f06d5de28d	2026-08-19 11:28:48.98208+08	WT20260819004
296	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_09_2	-1	0		\N	\N	\N	\N	dc872d9163b0ce3fab3ac05134fe322aeaefabdf483678b1250e67f06d5de28d	d7ed0cf571ebdcf318b83c9e6d6d14c407b9ea5cac4aff79914dfde59fc17c58	2026-08-19 11:28:48.983075+08	WT20260819004
297	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1	0.0	1.21		\N	\N	\N	\N	d7ed0cf571ebdcf318b83c9e6d6d14c407b9ea5cac4aff79914dfde59fc17c58	0206df7dc44b43c830c3780588c086092987fb466fc72bfea4364c72726e373c	2026-08-19 11:28:48.983973+08	WT20260819004
298	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1_reading1	0	1.08		\N	\N	\N	\N	0206df7dc44b43c830c3780588c086092987fb466fc72bfea4364c72726e373c	2a973eba13403300587d13727566240dbea4faaf6a398aa333293d3992da89df	2026-08-19 11:28:48.984828+08	WT20260819004
299	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1_reading2	0	1.31		\N	\N	\N	\N	2a973eba13403300587d13727566240dbea4faaf6a398aa333293d3992da89df	399fbb8098ed645452a970f32cc78e4a6f61a3843e4c5b48e3f3fb24f4a77ec2	2026-08-19 11:28:48.985724+08	WT20260819004
300	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1_reading3	0	1.24		\N	\N	\N	\N	399fbb8098ed645452a970f32cc78e4a6f61a3843e4c5b48e3f3fb24f4a77ec2	9ddc6610740d6a263de39ade34bc9843b78423a81f40659c49b71fb97f059261	2026-08-19 11:28:48.986581+08	WT20260819004
301	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi_mean	0.0	0.4		\N	\N	\N	\N	9ddc6610740d6a263de39ade34bc9843b78423a81f40659c49b71fb97f059261	3805a9e11db6819baef283ff382de2df8de279d46baeac1a1a589c1a990f91bf	2026-08-19 11:28:48.987537+08	WT20260819004
302	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	3805a9e11db6819baef283ff382de2df8de279d46baeac1a1a589c1a990f91bf	95de849536f5ee02828c37dc7bd4186e0ca54f31f9f1785d3db231d71ad975db	2026-08-19 11:28:53.680884+08	WT20260819004
317	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	f78b26643102765977cfcb991411c6ae095614cb025b63bfa424b3fdfe2bccf9	c318353b5480ee51cd8458c5b6752011f5407642a6112a2b05eba9c136911124	2026-08-19 11:29:31.898778+08	WT20260819004
318	record	BP20260819005-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	c318353b5480ee51cd8458c5b6752011f5407642a6112a2b05eba9c136911124	23568fc22f8c094c1583a8fa576dd6a5016e279932afd271b82528b346919db1	2026-08-19 11:31:50.511612+08	WT20260819004
319	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	report_summary	BP20260819005-S01：ROI平均灰度0	BP20260819005-S01：ROI平均灰度0.4		\N	\N	\N	\N	23568fc22f8c094c1583a8fa576dd6a5016e279932afd271b82528b346919db1	7be7cac26c9ba7d3f6e067b6ae37cb1dffd1ff2daa14ac4b6010687b8200a120	2026-08-19 11:31:50.512747+08	WT20260819004
320	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_1	1.2	2		\N	\N	\N	\N	7be7cac26c9ba7d3f6e067b6ae37cb1dffd1ff2daa14ac4b6010687b8200a120	5edae7ff0bc76d9c84ffa2a73bee92ddf48a7de1cf9fd69f29e11e1c40586f0f	2026-08-19 11:31:50.514387+08	WT20260819004
321	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_2	1.11	2		\N	\N	\N	\N	5edae7ff0bc76d9c84ffa2a73bee92ddf48a7de1cf9fd69f29e11e1c40586f0f	5efc817936de7219912adafd115c411a1ab947128f0bcac48b6712ed7b0d0388	2026-08-19 11:31:50.515524+08	WT20260819004
322	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_measured_3	1.21	2		\N	\N	\N	\N	5efc817936de7219912adafd115c411a1ab947128f0bcac48b6712ed7b0d0388	4058ef3e2d3d3c11951c93f659ee2626cf618ef224b87a256c9e367bc7a05d17	2026-08-19 11:31:50.516512+08	WT20260819004
323	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.density_nominal	0	2		\N	\N	\N	\N	4058ef3e2d3d3c11951c93f659ee2626cf618ef224b87a256c9e367bc7a05d17	41409c17705421a782fa108b81f9fce2ef3c5a1122355c16854a508b8ee8df06	2026-08-19 11:31:50.517388+08	WT20260819004
324	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_07_2	1	0		\N	\N	\N	\N	41409c17705421a782fa108b81f9fce2ef3c5a1122355c16854a508b8ee8df06	3fd3f9c3b1fbf3fd9c4391a3a16df1a1a253bb41965a224fd1e59a6fea317d34	2026-08-19 11:31:50.518072+08	WT20260819004
325	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_08_2	-1	0		\N	\N	\N	\N	3fd3f9c3b1fbf3fd9c4391a3a16df1a1a253bb41965a224fd1e59a6fea317d34	821fa060b5ed5e56554d9193891334ecccebed159a9eda341f68b8d6211b6c8d	2026-08-19 11:31:50.518656+08	WT20260819004
326	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.iqi_gray_09_2	-1	0		\N	\N	\N	\N	821fa060b5ed5e56554d9193891334ecccebed159a9eda341f68b8d6211b6c8d	fbcdaa1ae3ea076deeee52403b861d51a70e9cfadd04d6416ec548b3d0cb23fe	2026-08-19 11:31:50.519243+08	WT20260819004
327	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_form.radiation_safety		允许曝光		\N	\N	\N	\N	fbcdaa1ae3ea076deeee52403b861d51a70e9cfadd04d6416ec548b3d0cb23fe	3e6b8670eab00f2a4b2a5d0af512734a371acba52a54cd8cfe77aa414d3c6bfd	2026-08-19 11:31:50.519855+08	WT20260819004
328	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1	0.0	1.21		\N	\N	\N	\N	3e6b8670eab00f2a4b2a5d0af512734a371acba52a54cd8cfe77aa414d3c6bfd	36922c6e50f6929a984c2fa058bf157beb8e75fcdd0ae67451b6cbf28c08ecf7	2026-08-19 11:31:50.520601+08	WT20260819004
329	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1_reading1	0	1.08		\N	\N	\N	\N	36922c6e50f6929a984c2fa058bf157beb8e75fcdd0ae67451b6cbf28c08ecf7	a8b69b46c27dcbce818f5b87211feef7496905fc36ccf6da52659a02e1215302	2026-08-19 11:31:50.521214+08	WT20260819004
330	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1_reading2	0	1.31		\N	\N	\N	\N	a8b69b46c27dcbce818f5b87211feef7496905fc36ccf6da52659a02e1215302	53640d5b5baee3b430ccc7f96d30acbb08966c5892cca2996599a9d4487c285a	2026-08-19 11:31:50.52187+08	WT20260819004
331	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi1_reading3	0	1.24		\N	\N	\N	\N	53640d5b5baee3b430ccc7f96d30acbb08966c5892cca2996599a9d4487c285a	2d72313c77e36decf6c7732b1c4e22858f13e8845841475effdf8772a32e1efe	2026-08-19 11:31:50.522703+08	WT20260819004
332	record	BP20260819005-T01	liuhong_test	刘红	实验员	修改	_rows[0].roi_mean	0.0	0.4		\N	\N	\N	\N	2d72313c77e36decf6c7732b1c4e22858f13e8845841475effdf8772a32e1efe	c64bd16a8b3ba67b1565472688a6154cc4fb4db222fd8d6c7bc74f626f833fd2	2026-08-19 11:31:50.523387+08	WT20260819004
333	commission	WT20260819005	admin	赵衡	管理员	创建委托	\N	\N	\N	\N	\N	\N	\N	\N	c64bd16a8b3ba67b1565472688a6154cc4fb4db222fd8d6c7bc74f626f833fd2	1b66ae0c8ffb461385d708909156e16363c43fb43417b03b3b302452988857ff	2026-08-19 11:50:36.490745+08	WT20260819005
334	sample_group	BP20260819006	admin	赵衡	管理员	创建样品组	\N	\N	\N	\N	\N	\N	\N	\N	1b66ae0c8ffb461385d708909156e16363c43fb43417b03b3b302452988857ff	01af0146c4eb72d44b2e14e20bc04094237f247d3abc6bd8cb877e9fdbb50e29	2026-08-19 11:50:36.509972+08	WT20260819005
335	task_package	BAG-BP20260819006-P01	admin	赵衡	管理员	创建任务包	\N	\N	\N	\N	\N	\N	\N	\N	01af0146c4eb72d44b2e14e20bc04094237f247d3abc6bd8cb877e9fdbb50e29	9b0eea5a5b0937af55b0a932476fcb87c84f5ab858cbd2ad84e41bc4e1c5a80c	2026-08-19 11:50:48.481523+08	WT20260819005
336	task_package	BAG-BP20260819006-P01	liuhong_test	刘红	实验员	接收任务包	\N	\N	\N	\N	\N	\N	\N	\N	9b0eea5a5b0937af55b0a932476fcb87c84f5ab858cbd2ad84e41bc4e1c5a80c	85a0dbc5b1b1debe3981d3555f30af8d912fb6edc0c56e3ff17947b7b273459d	2026-08-19 11:51:18.315151+08	WT20260819005
337	record	BP20260819006-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	85a0dbc5b1b1debe3981d3555f30af8d912fb6edc0c56e3ff17947b7b273459d	e3e70c03732d973bd53ea624b0707df8e611efd98fc669c3680865f1d8b0a4fd	2026-08-19 11:51:23.303126+08	WT20260819005
338	record	BP20260819006-T01	liuhong_test	刘红	实验员	保存草稿	\N	\N	\N	\N	\N	\N	\N	\N	e3e70c03732d973bd53ea624b0707df8e611efd98fc669c3680865f1d8b0a4fd	a55f5cb7920032d649d77903186bcb83b7e30f922456cf2334b5ed328b7bdaed	2026-08-19 11:51:45.286394+08	WT20260819005
\.


--
-- Data for Name: commissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.commissions (commission_no, client_org_id, client_name, client_address, contact, phone, production_org_id, production_org_name, production_relation, commission_date, due_date, subcontract_allowed, report_medium, conformity_judgment, uncertainty, delivery_method, cnas_mark, capability, method_choices, notes, status, created_by, created_at, updated_at, archived_at, archived_by) FROM stdin;
WT20260817001	2	大连001义齿加工厂	大连市中山路100号	赵先生	888888	1	1	自产	2026-08-17	2026-09-16	\N	\N	\N	\N	\N	\N	\N	[]		已入库	admin	2026-08-17 15:07:43.80535+08	2026-08-17 15:07:43.80535+08	\N	\N
WT20260818001	2	大连001义齿加工厂	大连市中山路100号	赵先生	888888	2	大连001义齿加工厂	客户提供	2026-08-18	2026-09-17	\N	\N	\N	\N	\N	\N	\N	[]		已入库	receiver	2026-08-18 14:36:13.133585+08	2026-08-18 14:36:13.133585+08	\N	\N
WT20260819001	2	大连001义齿加工厂	大连市中山路100号	赵先生	888888	2	大连001义齿加工厂	自产	2026-08-19	2026-09-18	\N	\N	\N	\N	\N	\N	\N	[]		已入库	admin	2026-08-19 10:35:20.681743+08	2026-08-19 10:35:20.681743+08	\N	\N
WT20260819002	2	大连001义齿加工厂	大连市中山路100号	赵先生	888888	2	大连001义齿加工厂	客户提供	2026-08-19	2026-09-18	\N	\N	\N	\N	\N	\N	\N	[]		已入库	admin	2026-08-19 10:53:16.49662+08	2026-08-19 10:53:16.49662+08	\N	\N
WT20260819003	2	大连001义齿加工厂	大连市中山路100号	赵先生	888888	2	大连001义齿加工厂	客户提供	2026-08-19	2026-09-18	\N	\N	\N	\N	\N	\N	\N	[]		已入库	admin	2026-08-19 10:57:27.505625+08	2026-08-19 10:57:27.505625+08	\N	\N
WT20260819004	1	1				1	1	客户提供	2026-08-19	2026-09-18	\N	\N	\N	\N	\N	\N	\N	[]		已入库	admin	2026-08-19 11:00:02.247851+08	2026-08-19 11:00:02.247851+08	\N	\N
WT20260819005	2	大连001义齿加工厂	大连市中山路100号	赵先生	888888	2	大连001义齿加工厂	客户提供	2026-08-19	2026-09-18	\N	\N	\N	\N	\N	\N	\N	[]		已入库	admin	2026-08-19 11:50:36.48345+08	2026-08-19 11:50:36.48345+08	\N	\N
\.


--
-- Data for Name: device_presets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.device_presets (experiment, equipment_name, equipment_model, equipment_no, calibration_certificate, calibration_due, software, default_location, extra_json, updated_by, updated_at) FROM stdin;
\.


--
-- Data for Name: document_versions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.document_versions (id, entity_type, entity_id, version, status, snapshot_json, snapshot_hash, created_by, created_at, obsolete_by, obsolete_at) FROM stdin;
\.


--
-- Data for Name: equipment_incident_actions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.equipment_incident_actions (id, incident_no, actor, action, comment, created_at) FROM stdin;
\.


--
-- Data for Name: equipment_incidents; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.equipment_incidents (incident_no, task_no, equipment_no, fault_type, fault_description, status, quality_conclusion, impact_scope, recovery_route, created_by, created_at, updated_at, package_no, group_id, equipment_name, reporter, occurred_at, error_code, current_stage, completed_steps, collected_data, sample_condition, risk_types, immediate_actions, involved_samples, frozen_record_version, isolation_location, storage_requirements, sample_validity, receiver_note, receiver_by, receiver_at, quality_note, quality_by, quality_at, backup_equipment_no, performance_check_result, admin_note, approved_by, approved_at, resumed_record_version, closed_at) FROM stdin;
\.


--
-- Data for Name: equipment_registry; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.equipment_registry (management_no, seq, equipment_name, model, measuring_range, manufacturer, serial_no, purchase_time, calibration_time, responsible, equipment_class, enabled, lifecycle_status, status_note, notes, created_at, updated_at, calibration_due, calibration_certificate) FROM stdin;
BPGL-A020	\N	热膨胀测试仪	ZRPY-1000	最高温1000 ℃；位移量程：（0～3）mm	湘潭市湘芸仪器设备有限公司	20251015002	2026.3	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A023	\N	挠度计	B531C	（0～25）mm，0.001 mm	成都远恒精密测控技术有限公司	3237	2026.3	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A024	\N	耐光色稳定性测试仪	SGJ611Y	水浴温度（37±1）℃；氙灯辐照度调节范围（2.5～170000）lx；计时范围（0～999999）h	温州三工匠仪器有限公司	204013	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A025	\N	电子天平	JA503E	（0～500）g；Ⅱ级	常州市幸运电子设备有限公司	1022605277	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A026	\N	影像测量仪	VMS-2010		东莞市辰量仪器设备有限公司	CL20241028	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A033	\N	干式激光成像仪	DryView5700C/6950	/	锐珂（上海）医疗器材有限公司	69135596	2026.5	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A034	\N	高精度铂电阻温度检测仪	YET-710	（-40～200）℃	深圳宇问测量技术有限公司	26056126	2026.5	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A035	\N	数显维氏硬度计	HV-30Z	HV10	上海尚材试验机有限公司	14053	2026.2	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A036	\N	粗糙度仪	TR200	±160 μm	掘扬精密量仪有限公司	SR260117E013	2026.5	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B001	\N	粗糙度标准块		Ra 1.61 μm	掘扬精密量仪有限公司		2026.5	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B002	\N	研磨粗糙度块	/	Ra 0.1 μm、Ra 0.05 μm、Ra 0.025 μm	潍坊华光量具有限公司	/	2026.2	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B003	\N	比色板	3D-MASTER	26色	德国维他公司	VT-G360	2026.2	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B005	\N	密度片	DV-9A	0.00～5.00 D	济宁科锐检测仪器有限公司	265083	2026.5	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B006	\N	背景板			揭阳鸿曦光电有限公司		2026.5	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B007	\N	标准维氏硬度块	况氏	466HV10	南昌况氏	V261-176	2026.2	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B008	\N	三点弯曲试验夹具			厦门易仕特仪器有限公司		2026.3	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B009	\N	金瓷结合试验夹具			厦门易仕特仪器有限公司		2026.3	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B010	\N	挠曲弹性试验夹具			厦门易仕特仪器有限公司		2026.3	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B011	\N	拉力试验夹具			厦门易仕特仪器有限公司		2026.3	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B012	\N	翘曲变形切割试验夹具			厦门易仕特仪器有限公司		2026.3	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C001	\N	核辐射检测仪	SF999	γ射线、X射线、β射线；剂量当前率：（0.00～1000）μSv/h；灵敏度：80 CPM/μSv（对于Co-60）	天津瞭望光电科技有限公司	20260121392	2026.3	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C002	\N	放大镜	10X	10X	惠州市齐力电子	/	2026.3	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C003	\N	放大镜	3X	3X	惠州市齐力电子	/	2026.3	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C004	\N	牙科探针					2026.3	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C005	\N	容量瓶	A	500 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C006	\N	容量瓶	A	1000 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C007	\N	量筒	/	100 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C008	\N	量筒	/	1000 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C009	\N	量筒	/	50 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C010	\N	量筒	/	25 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C011	\N	移液管	A	10 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A042	\N	电子密度天平	FA2204T·S	（0～220）g，Ⅰ级，0.0001 g	常州市幸运电子设备有限公司	1032606050	\N	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B013	\N	标准砝码	200 g	200 g	常州市幸运电子设备有限公司		\N	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B014	\N	标准砝码	200 g	200 g	常州市幸运电子设备有限公司		\N	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A043	\N	循环侵泡仪					\N	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B015	\N	游标万能角度尺	（0～320）°	（0～320）°	河南省邦特工量具有限公司(卡西洛）	H320317	2026.6	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B016	\N	孔型像质计	钴铬合金				2026.6	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B017	\N	孔型像质计	钛合金				2026.6	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B018	\N	孔型像质计	纯钛				2026.6	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B019	\N	平行块	（30×6×5）mm				\N	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B020	\N	挠曲强度平行块	（70×6×5）mm				\N	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B021	\N	金相显微镜校正片	VSJ-D004	0.1 mm			\N	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B022	\N	影像测量仪标准块					\N	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B023	\N	密度块		ρ=4.506；ρ=8.67			\N	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B024	\N	数位采集板					\N	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A001	\N	数显游标卡尺		（0～150）mm			2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A002	\N	金相显微镜	CX40M			2207111979	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A003	\N						2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A004	\N	螺纹千分尺		（0～25）mm		230308408	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A005	\N	测厚仪	/	（0～10）mm/0.1 mm	上海九量五金工具有限公司	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A006	\N	电子秒表	YS-801	0.01 s～99 h 59 min 59.99 s；分辨力：0.01 s	深圳市弈圣科技有限公司	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A007	\N	电子秒表	YS-801	0.01 s～99 h 59 min 59.99 s；分辨力：0.01 s	深圳市弈圣科技有限公司	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A008	\N	电子秒表	YS-801	0.01 s～99 h 59 min 59.99 s；分辨力：0.01 s	深圳市弈圣科技有限公司	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A009	\N	温湿度计	YZ-0508	温度：（-10～60）℃；相对湿度：（0～100）%	扬子		2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A010	\N	温湿度计	YZ-0508	温度：（-10～60）℃；相对湿度：（0～100）%	扬子		2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A011	\N	温湿度计	YZ-0508	温度：（-10～60）℃；相对湿度：（0～100）%	扬子		2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A012	\N	温湿度计	/	温度：（-10～60）℃；相对湿度：（0～100）%	蓝骏	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A013	\N	温湿度计	/	温度：（-10～60）℃；相对湿度：（0～100）%	蓝骏	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A014	\N	温湿度计	/	温度：（-10～60）℃；相对湿度：（0～100）%	蓝骏	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A015	\N	温湿度计	/	温度：（-10～60）℃；相对湿度：（0～100）%	蓝骏	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A016	\N	温湿度计	/	温度：（-10～60）℃；相对湿度：（0～100）%	蓝骏	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A017	\N	数显恒温水浴锅	OW-HF	（5～99.9）℃/0.1 ℃	浙江欧迈科实验仪器有限公司	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A018	\N	高速精密切割机	GTQ-5000B	（500～5000）rpm；进刀速度0.01～3 mm/s	莱州市蔚仪试验器械制造有限公司	02079	2026.3	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A019	\N	金相试样抛光机	P-2T	/	莱州市蔚仪试验器械制造有限公司	03127	2026.3	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A022	\N	电子引伸计	YYJ-5/10-L	（0～5.0）mm，0.5级；标距10.0 mm	钢研纳克检测技术股份有限公司	260003	2026.3	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A027	\N	超声波清洗机	VGT-1620T	超声频率40 kHz；超声功率50 W	广东固特超声股份有限公司	ZZ003635F0002	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A028	\N	D65对色灯箱		色温：标准6500 K，误差≤±200 K；工业对色最低要求：Ra≥95；箱内工作面照度：500～2000 lux	工游记工业科技（深圳）有限公司	722773	2026.5	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A029	\N	黑白密度计	KM-500	0.00～5.00 D	济宁科锐检测仪器有限公司	124506	2026.5	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A030	\N	电热恒温干燥箱	101-00	加热功率900 W；控温分辨率1 ℃；（50～250）℃；定时范围（1～9999）min	上海翰雨科技有限公司	951048	2026.5	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A031	\N	微机型酸度计	PHS-3DW	pH（0～14），0.01级	杭州齐威仪器有限公司	M5260611001	2026.5	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A032	\N	医用X射线限束器	R103	X射线泄漏：<0.5 mGy/h（120 kV、4 mA）	丹东市科大仪器有限公司		2026.5	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-B004	\N	基托比色板					2026.2	\N		B类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C012	\N	通风橱	/	/	/	/	2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C013	\N	量筒	/	50 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C014	\N	量筒	/	25 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C015	\N	量筒	/	25 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C016	\N	量筒	/	25 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C017	\N	量筒	/	100 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C018	\N	容量瓶	A	1000 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C019	\N	容量瓶	A	500 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C020	\N	容量瓶	A	250 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C021	\N	容量瓶	A	250 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C022	\N	容量瓶	A	250 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C023	\N	容量瓶	A	250 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C024	\N	容量瓶	A	250 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C025	\N	容量瓶	A	100 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C026	\N	容量瓶	A	100 mL	BOMEX		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C027	\N	移液管	A	10 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C028	\N	移液管	A	1 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C029	\N	移液管	A	1 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C030	\N	移液管	A	2 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C031	\N	移液管	A	2 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-C032	\N	移液管	A	5 mL	天玻		2026.5	\N		C类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A037	\N	电子秒表	YS-860	0.01 s～99 h 59 min 59.99 s；分辨力：0.01 s	深圳市弈圣科技有限公司	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A038	\N	电子秒表	YS-860	0.01 s～99 h 59 min 59.99 s；分辨力：0.01 s	深圳市弈圣科技有限公司	/	2026.4	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A039	\N	照度计	/	（0～200000）Lux；±3%rdg（＜10000 Lux）；±4%rdg（＞10000 Lux）	得力	DL333204	\N	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A040	\N	大理石平台		（300×200）mm，00级	山光		\N	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A041	\N	高精度数字水平仪	Dasqua	±0.01 mm/m			\N	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-13 12:38:27.147337+08	\N	\N
BPGL-A021	\N	电子万能试验机	STS50K	（0～50）kN，0.5级；（0～2000）N，0.5级	厦门易仕特仪器有限公司	20260323020	2026.3	\N		A类	t	启用	\N	\N	2026-08-12 11:38:25.664471+08	2026-08-17 16:22:43.299439+08	\N	\N
\.


--
-- Data for Name: experiment_config_columns; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experiment_config_columns (id, config_id, column_key, column_label, column_type, is_required, column_default, calc_expression, calc_precision, sort_order) FROM stdin;
1123	17	sample_no	试样编号	text	f			3	0
1124	17	surface_confirm	原打印面/方向确认	select:符合|不符合	f	符合		3	1
1125	17	position	测量位置	text	f			3	2
1126	17	ra1	Ra1/μm	number	f			3	3
1127	17	ra2	Ra2/μm	number	f			3	4
1128	17	ra3	Ra3/μm	number	f			3	5
1129	17	mean	平均值/μm	calc	f		{"column_key":"mean","op":"avg","inputs":["ra1","ra2","ra3"],"args":{"precision":3}}	3	6
1130	17	limit	判定限值/μm	number	f	15		3	7
1131	17	conclusion	单样结论	calc	f		{"column_key":"conclusion","op":"le","inputs":["mean","limit"],"args":{"constant":15,"true_value":"符合","false_value":"不符合"}}	3	8
1132	17	retest_mean	复测后平均/μm	number	f			3	9
1133	17	file_no	曲线/数据文件编号	text	f			3	10
1134	17	note	备注	text	f			3	11
1222	2	sample_no	试样编号	text	f			3	0
1223	2	width	宽度/mm	number	f			3	1
1224	2	dm1	金属厚度1/mm	number	f			3	2
1225	2	dm2	金属厚度2/mm	number	f			3	3
1226	2	dm3	金属厚度3/mm	number	f			3	4
1227	2	mean	金属厚度平均/mm	calc	f		{"column_key":"dm_mean","op":"avg","inputs":["dm1","dm2","dm3"],"args":{"precision":4}}	3	5
1228	2	em	金属弹性模量/GPa	number	f			3	6
1229	2	k	K/mm⁻²	number	f			3	7
1230	2	ffail	裂纹萌生力/N	number	f			3	8
1231	2	tau	结合强度/MPa	calc	f		{"column_key":"tau","op":"multiply","inputs":["k","ffail"],"args":{"precision":2}}	3	9
1232	2	crack_position	开裂位置	text	f			3	10
1233	2	failure_mode	断裂/剥离形态	text	f			3	11
1234	2	curve_no	曲线/数据文件编号	text	f			3	12
1235	2	conclusion	单样结论	calc	f		{"column_key":"conclusion","op":"gt","inputs":["tau"],"args":{"constant":25,"true_value":"符合","false_value":"不符合"}}	3	13
1236	2	note	备注	text	f			3	14
1387	3	sample_no	样品编号	text	f			3	0
1388	3	sample_name_tooth	样品名称/牙位	text	f			3	1
1389	3	image_no	图像文件编号	text	f			3	2
1390	3	sample_status	样品状态	select:完好|异常	f	完好		3	3
1391	3	image_valid	图像有效性	select:有效|无效	f	有效		3	4
1392	3	iqi_display	像质计显示	select:清晰|不清晰	f	清晰		3	5
1393	3	roi1_reading1	ROI-1灰度·第1次	number	f			3	6
1394	3	roi1_reading2	ROI-1灰度·第2次	number	f			3	7
1395	3	roi1_reading3	ROI-1灰度·第3次	number	f			3	8
1396	3	roi2_reading1	ROI-2灰度·第1次	number	f			3	9
1397	3	roi2_reading2	ROI-2灰度·第2次	number	f			3	10
1398	3	roi2_reading3	ROI-2灰度·第3次	number	f			3	11
1399	3	roi3_reading1	ROI-3灰度·第1次	number	f			3	12
1400	3	roi3_reading2	ROI-3灰度·第2次	number	f			3	13
1401	3	roi3_reading3	ROI-3灰度·第3次	number	f			3	14
1402	3	roi1	ROI-1平均灰度	calc	f		{"op":"avg","inputs":["roi1_reading1","roi1_reading2","roi1_reading3"],"args":{"precision":2,"true_value":"符合","false_value":"不符合"}}	2	15
1403	3	roi2	ROI-2平均灰度	calc	f		{"op":"avg","inputs":["roi2_reading1","roi2_reading2","roi2_reading3"],"args":{"precision":2,"true_value":"符合","false_value":"不符合"}}	2	16
1404	3	roi3	ROI-3平均灰度	calc	f		{"op":"avg","inputs":["roi3_reading1","roi3_reading2","roi3_reading3"],"args":{"precision":2,"true_value":"符合","false_value":"不符合"}}	2	17
1405	3	roi_mean	ROI平均灰度	calc	f		{"op":"avg","inputs":["roi1","roi2","roi3"],"args":{"precision":2,"true_value":"符合","false_value":"不符合"}}	2	18
1406	3	thickness_relation	接近/介于像质计厚度点	text	f			3	19
1407	3	estimated_thickness	厚度估算结果	text	f			3	20
1408	3	defect	异常影像/位置	text	f			3	21
1409	3	retake	是否复拍	select:否|是	f	否		3	22
1410	3	conclusion	单样结论	select:合格|不合格|需复检|超出适用范围	f	合格		3	23
1411	3	note	备注	text	f			3	24
979	4	sample_no	试样编号	text	t			3	1
980	4	h1	H1/mm	number	t			3	2
981	4	h2	H2/mm	number	t			3	3
982	4	cut_start	切割开始时间	text	t			3	4
983	4	cut_end	切割结束时间	text	t			3	5
984	4	coolant_status	冷却液持续供给	select	t	是|否		3	6
985	4	remade	是否重新制样	select	t	否|是		3	7
986	4	delta	ΔH=H1-H2/mm	calc	t		{"column_key": "delta", "op": "subtract", "inputs": ["h1", "h2"], "args": {"precision": 4}}	3	8
987	4	limit	判定限值/mm	number	t	0.5		3	9
988	4	edge_condition	切口崩边/裂纹状态	text	t			3	10
989	4	conclusion	单样结论	calc	t		{"column_key": "conclusion", "op": "abs_le", "inputs": ["delta", "limit"], "args": {"constant": 0.5, "true_value": "合格", "false_value": "不合格"}}	3	11
990	4	note	备注	text	t			3	12
991	5	sample_no	试样编号	text	t			3	1
992	5	l0	初始长度L0/mm	number	t			3	2
993	5	diameter	直径/mm	number	t			3	3
994	5	installation_direction	安装方向	select	t	正确|不适用		3	4
995	5	sample_secure	是否牢固	select	t	是|否		3	5
996	5	run_status	升温状态	select	t	正常|异常		3	6
997	5	auto_stop	自动停止	select	t	是|否		3	7
998	5	validity	有效性	select	t	有效|无效		3	8
999	5	t1	起始温度/℃	number	t	25.0		3	9
1000	5	t2	终止温度/℃	number	t	550.0		3	10
1001	5	delta_l	长度变化ΔL/μm	number	t			3	11
1002	5	delta_t	温差ΔT/℃	calc	t		{"column_key": "delta_t", "op": "subtract", "inputs": ["t2", "t1"], "args": {"precision": 3}}	3	12
1003	5	alpha	线胀系数/(10⁻⁶/K)	calc	t		{"column_key": "alpha", "op": "divide", "inputs": ["delta_l", "l0", "delta_t"], "args": {"constant": 1000, "precision": 3}}	3	13
1004	5	nominal_value	标称值/(10⁻⁶/K)	number	t			3	14
689	18	sample_no	试样编号	text	t			3	1
690	18	width	宽度/mm	number	t			3	2
691	18	dm1	金属厚度1/mm	number	t			3	3
692	18	dm2	金属厚度2/mm	number	t			3	4
693	18	dm3	金属厚度3/mm	number	t			3	5
694	18	dm_mean	金属厚度平均/mm	calc	t		{"column_key": "dm_mean", "op": "avg", "inputs": ["dm1", "dm2", "dm3"], "args": {"precision": 4}}	3	6
695	18	em	金属弹性模量/GPa	number	t			3	7
696	18	k	K/mm⁻²	number	t			3	8
697	18	ffail	裂纹萌生力/N	number	t			3	9
698	18	tau	结合强度/MPa	calc	t		{"column_key": "tau", "op": "multiply", "inputs": ["k", "ffail"], "args": {"precision": 2}}	3	10
699	18	crack_position	开裂位置	text	t			3	11
700	18	failure_mode	断裂/剥离形态	text	t			3	12
701	18	curve_no	曲线/数据文件编号	text	t			3	13
702	18	conclusion	单样结论	calc	t		{"column_key": "conclusion", "op": "gt", "inputs": ["tau"], "args": {"constant": 25, "true_value": "符合", "false_value": "不符合"}}	3	14
703	18	note	备注	text	t			3	15
704	19	sample_no	样品编号	text	t			3	1
705	19	sample_name_tooth	样品名称/牙位	text	t			3	2
706	19	image_no	图像文件编号	text	t			3	3
707	19	sample_status	样品状态	select	t	完好|异常		3	4
708	19	image_valid	图像有效性	select	t	有效|无效		3	5
709	19	iqi_display	像质计显示	select	t	清晰|不清晰		3	6
710	19	roi1_reading1	ROI-1灰度·第1次	number	t			3	7
711	19	roi1_reading2	ROI-1灰度·第2次	number	t			3	8
712	19	roi1_reading3	ROI-1灰度·第3次	number	t			3	9
713	19	roi2_reading1	ROI-2灰度·第1次	number	t			3	10
714	19	roi2_reading2	ROI-2灰度·第2次	number	t			3	11
715	19	roi2_reading3	ROI-2灰度·第3次	number	t			3	12
716	19	roi3_reading1	ROI-3灰度·第1次	number	t			3	13
717	19	roi3_reading2	ROI-3灰度·第2次	number	t			3	14
718	19	roi3_reading3	ROI-3灰度·第3次	number	t			3	15
719	19	roi1	ROI-1平均灰度	calc	t		{"column_key": "roi1", "op": "avg", "inputs": ["roi1_reading1", "roi1_reading2", "roi1_reading3"], "args": {"precision": 2}}	3	16
720	19	roi2	ROI-2平均灰度	calc	t		{"column_key": "roi2", "op": "avg", "inputs": ["roi2_reading1", "roi2_reading2", "roi2_reading3"], "args": {"precision": 2}}	3	17
721	19	roi3	ROI-3平均灰度	calc	t		{"column_key": "roi3", "op": "avg", "inputs": ["roi3_reading1", "roi3_reading2", "roi3_reading3"], "args": {"precision": 2}}	3	18
722	19	roi_mean	ROI平均灰度	calc	t		{"column_key": "roi_mean", "op": "avg", "inputs": ["roi1", "roi2", "roi3"], "args": {"precision": 2}}	3	19
723	19	thickness_relation	接近/介于像质计厚度点	text	t			3	20
724	19	estimated_thickness	厚度估算结果	text	t			3	21
725	19	defect	异常影像/位置	text	t			3	22
726	19	retake	是否复拍	select	t	否|是		3	23
727	19	conclusion	单样结论	select	t	合格|不合格|需复检|超出适用范围		3	24
728	19	note	备注	text	t			3	25
729	20	sample_no	试样编号	text	t			3	1
730	20	h1	H1/mm	number	t			3	2
731	20	h2	H2/mm	number	t			3	3
732	20	cut_start	切割开始时间	text	t			3	4
733	20	cut_end	切割结束时间	text	t			3	5
734	20	coolant_status	冷却液持续供给	select	t	是|否		3	6
735	20	remade	是否重新制样	select	t	否|是		3	7
736	20	delta	ΔH=H1-H2/mm	calc	t		{"column_key": "delta", "op": "subtract", "inputs": ["h1", "h2"], "args": {"precision": 4}}	3	8
737	20	limit	判定限值/mm	number	t	0.5		3	9
738	20	edge_condition	切口崩边/裂纹状态	text	t			3	10
739	20	conclusion	单样结论	calc	t		{"column_key": "conclusion", "op": "abs_le", "inputs": ["delta", "limit"], "args": {"constant": 0.5, "true_value": "合格", "false_value": "不合格"}}	3	11
740	20	note	备注	text	t			3	12
741	21	sample_no	试样编号	text	t			3	1
742	21	l0	初始长度L0/mm	number	t			3	2
743	21	diameter	直径/mm	number	t			3	3
744	21	installation_direction	安装方向	select	t	正确|不适用		3	4
745	21	sample_secure	是否牢固	select	t	是|否		3	5
746	21	run_status	升温状态	select	t	正常|异常		3	6
747	21	auto_stop	自动停止	select	t	是|否		3	7
748	21	validity	有效性	select	t	有效|无效		3	8
749	21	t1	起始温度/℃	number	t	25.0		3	9
750	21	t2	终止温度/℃	number	t	550.0		3	10
751	21	delta_l	长度变化ΔL/μm	number	t			3	11
752	21	delta_t	温差ΔT/℃	calc	t		{"column_key": "delta_t", "op": "subtract", "inputs": ["t2", "t1"], "args": {"precision": 3}}	3	12
753	21	alpha	线胀系数/(10⁻⁶/K)	calc	t		{"column_key": "alpha", "op": "divide", "inputs": ["delta_l", "l0", "delta_t"], "args": {"constant": 1000, "precision": 3}}	3	13
754	21	nominal_value	标称值/(10⁻⁶/K)	number	t			3	14
755	21	sample_standard_value	样品标准值/(10⁻⁶/K)	number	t			3	15
756	21	judgement_basis	判定依据	select	t	委托要求		3	16
757	21	judgement_standard	判定标准	text	t			3	17
758	21	judgement_result	判定结果	select	t	符合|不符合		3	18
759	21	curve_no	设备数据文件编号	text	t			3	19
760	21	note	备注	text	t			3	20
761	22	sample_no	样品编号/位置	text	t			3	1
762	22	initial_appearance	初始外观	select	t	无异常|有异常		3	2
763	22	crack	裂纹	select	t	无|有		3	3
764	22	chipping	崩瓷	select	t	无|有		3	4
765	22	fracture	破裂/裂开	select	t	无|有		3	5
766	22	photo_no	观察照片编号	text	t			3	6
767	22	conclusion	单样结论	calc	t		{"column_key": "conclusion", "op": "all_eq", "inputs": ["crack", "chipping", "fracture"], "args": {"match": "无", "true_value": "符合", "false_value": "不符合"}}	3	7
768	22	note	备注	text	t			3	8
769	23	sample_no	试样编号	text	t			3	1
770	23	length	长度/mm	number	t	25.0		3	2
771	23	width	宽度/mm	number	t	2.0		3	3
772	23	height	高度/mm	number	t	2.0		3	4
773	23	span	支点距/mm	number	t	20.0		3	5
774	23	speed	速度/mm/min	number	t	1.0		3	6
775	23	fmax	Fmax/N	number	t			3	7
776	23	stress_02	0.2%规定非比例弯曲应力/MPa	number	t			3	8
777	23	curve_no	曲线/数据文件编号	text	t			3	9
778	23	sample_state	试样状态	select	t	完整|断裂|异常		3	10
779	23	conclusion	单样结论	calc	t		{"column_key": "conclusion", "op": "ge", "inputs": ["stress_02"], "args": {"constant": 800, "true_value": "符合", "false_value": "不符合"}}	3	11
780	23	note	备注	text	t			3	12
781	24	sample_no	样品编号	text	t			3	1
782	24	face	测量方向	text	t			3	2
783	24	indent1	压痕1/HV	number	t			3	3
784	24	indent2	压痕2/HV	number	t			3	4
785	24	indent3	压痕3/HV	number	t			3	5
786	24	mean	测试面平均/HV	calc	t		{"column_key": "mean", "op": "avg", "inputs": ["indent1", "indent2", "indent3"], "args": {"precision": 1}}	3	6
787	24	indent_quality	压痕有效性	select	t	有效|无效		3	7
788	24	image_no	压痕图像编号	text	t			3	8
789	24	note	备注	text	t			3	9
790	25	sample_no	试样编号	text	t			3	1
791	25	r1_fixed_p1	重复1·固定端P1/mm	number	t			3	2
792	25	r1_fixed_p2	重复1·固定端P2/mm	number	t			3	3
793	25	r1_fixed_p3	重复1·固定端P3/mm	number	t			3	4
794	25	r1_middle_p1	重复1·中点P1/mm	number	t			3	5
795	25	r1_middle_p2	重复1·中点P2/mm	number	t			3	6
796	25	r1_middle_p3	重复1·中点P3/mm	number	t			3	7
797	25	r1_free_p1	重复1·自由端P1/mm	number	t			3	8
798	25	r1_free_p2	重复1·自由端P2/mm	number	t			3	9
799	25	r1_free_p3	重复1·自由端P3/mm	number	t			3	10
800	25	fixed_mean	固定端总平均/mm	calc	t		{"column_key": "fixed_mean", "op": "avg", "inputs": ["r1_fixed_p1", "r1_fixed_p2", "r1_fixed_p3"], "args": {"precision": 4}}	3	11
801	25	middle_mean	中点总平均/mm	calc	t		{"column_key": "middle_mean", "op": "avg", "inputs": ["r1_middle_p1", "r1_middle_p2", "r1_middle_p3"], "args": {"precision": 4}}	3	12
802	25	free_mean	自由端总平均/mm	calc	t		{"column_key": "free_mean", "op": "avg", "inputs": ["r1_free_p1", "r1_free_p2", "r1_free_p3"], "args": {"precision": 4}}	3	13
803	25	mean	试样总平均/mm	calc	t		{"column_key": "mean", "op": "avg", "inputs": ["r1_fixed_p1", "r1_fixed_p2", "r1_fixed_p3", "r1_middle_p1", "r1_middle_p2", "r1_middle_p3", "r1_free_p1", "r1_free_p2", "r1_free_p3"], "args": {"precision": 4}}	3	14
804	25	deviation	尺寸偏差/mm	calc	t			3	15
805	25	limit	判定要求/mm	text	t			3	16
806	25	conclusion	单样结论	text	t			3	17
807	25	image_no	图像编号	text	t			3	18
808	25	note	备注	text	t			3	19
824	27	sample_no	样品编号	text	t			3	1
825	27	unit_name	牙位	text	t			3	2
826	27	surface_check	表面检查	select	t	合格|不合格		3	3
827	27	margin_gap	边缘间隙/μm	number	t			3	4
828	27	roughness	粗糙度Ra/μm	number	t			3	5
829	27	porosity	孔隙度/%	number	t			3	6
830	27	conclusion	单样结论	calc	t			3	7
831	27	note	备注	text	t			3	8
832	28	sample_no	样品编号	text	t			3	1
833	28	check_item	检查项目	text	t			3	2
834	28	result	结果	select	t	合格|不合格		3	3
835	28	conclusion	单样结论	calc	t			3	4
836	28	note	备注	text	t			3	5
837	29	sample_no	试样编号	text	t			3	1
838	29	a1	测量1空气中质量A/g	number	t			3	2
839	29	b1	测量1水中表观质量B/g	number	t			3	3
840	29	water_temp1	测量1水温/℃	number	t			3	4
841	29	water_density1	测量1水密度/(g/cm³)	number	t			3	5
842	29	auto_density1	测量1天平密度	number	t			3	6
843	29	density1	测量1复算密度	calc	t			3	7
844	29	a2	测量2空气中质量A/g	number	t			3	8
845	29	b2	测量2水中表观质量B/g	number	t			3	9
846	29	water_temp2	测量2水温/℃	number	t			3	10
847	29	water_density2	测量2水密度/(g/cm³)	number	t			3	11
848	29	auto_density2	测量2天平密度	number	t			3	12
849	29	density2	测量2复算密度	calc	t			3	13
850	29	a3	测量3空气中质量A/g	number	t			3	14
851	29	b3	测量3水中表观质量B/g	number	t			3	15
852	29	water_temp3	测量3水温/℃	number	t			3	16
853	29	water_density3	测量3水密度/(g/cm³)	number	t			3	17
854	29	auto_density3	测量3天平密度	number	t			3	18
855	29	density3	测量3复算密度	calc	t			3	19
856	29	density_difference	最大密度差/(g/cm³)	calc	t			3	20
857	29	mean	平均密度/(g/cm³)	calc	t			3	21
858	29	relative_deviation	相对偏差/%	calc	t			3	22
859	29	conclusion	单样结论	calc	t			3	23
860	29	data_file_no	数据文件编号	text	t			3	24
861	29	note	备注	text	t			3	25
862	30	sample_no	试样编号	text	t			3	1
863	30	specimen_role	试样用途	select	t	浸泡试样|未浸泡对照		3	2
864	30	diameter	直径/mm	number	t			3	3
865	30	thickness	厚度/mm	number	t			3	4
866	30	surface_prep	表面制备	select	t	符合|不符合		3	5
867	30	color_change	颜色变化	select	t	无|极轻微|明显		3	6
868	30	tarnish_product	晦暗产物	select	t	无|有		3	7
869	30	removal_ease	轻柔刷洗/擦拭去除性	select	t	易去除|不易去除|不适用		3	8
870	30	reflectance_change	反射率变化（仅报告）	text	t			3	9
871	30	conclusion	单样结论	calc	t			3	10
872	30	note	备注	text	t			3	11
912	26	sample_no	试样编号	text	f			3	0
913	26	control_no	对照试样编号	text	f			3	1
914	26	shape	试样形状	select:圆片|牙形|其他	f	圆片		3	2
915	26	size	试样尺寸	text	f			3	3
916	26	cover_method	遮盖方式	select:试样夹|锡箔|铝箔	f	试样夹		3	4
917	26	cover_direction	遮盖区域/方向	text	f			3	5
918	26	cover_secure	遮盖是否牢固	select:是|否	f	是		3	6
919	26	position	摆放位置	text	f			3	7
920	26	photo_no	照射前/后照片编号	text	f			3	8
921	26	observer1	观察者1结果	select:未见明显差异|轻微差异|明显差异|无法判定	f	未见明显差异		3	9
922	26	observer2	观察者2结果	select:未见明显差异|轻微差异|明显差异|无法判定	f	未见明显差异		3	10
923	26	observer3	观察者3结果	select:未见明显差异|轻微差异|明显差异|无法判定	f	未见明显差异		3	11
924	26	overall	总体观察结果	calc	f		{"column_key":"overall","op":"color_overall","inputs":["observer1","observer2","observer3"],"args":{}}	3	12
925	26	conclusion	单样结论	calc	f		{"column_key":"conclusion","op":"color_conclusion","inputs":["observer1","observer2","observer3"],"args":{}}	3	13
926	26	note	备注	text	f			3	14
1005	5	sample_standard_value	样品标准值/(10⁻⁶/K)	number	t			3	15
1006	5	judgement_basis	判定依据	select	t	委托要求		3	16
1007	5	judgement_standard	判定标准	text	t			3	17
1008	5	judgement_result	判定结果	select	t	符合|不符合		3	18
1009	5	curve_no	设备数据文件编号	text	t			3	19
1010	5	note	备注	text	t			3	20
1011	6	sample_no	样品编号/位置	text	t			3	1
1012	6	initial_appearance	初始外观	select	t	无异常|有异常		3	2
1013	6	crack	裂纹	select	t	无|有		3	3
1014	6	chipping	崩瓷	select	t	无|有		3	4
1015	6	fracture	破裂/裂开	select	t	无|有		3	5
1016	6	photo_no	观察照片编号	text	t			3	6
1017	6	conclusion	单样结论	calc	t		{"column_key": "conclusion", "op": "all_eq", "inputs": ["crack", "chipping", "fracture"], "args": {"match": "无", "true_value": "符合", "false_value": "不符合"}}	3	7
1018	6	note	备注	text	t			3	8
1019	7	sample_no	试样编号	text	t			3	1
1020	7	length	长度/mm	number	t	25.0		3	2
1021	7	width	宽度/mm	number	t	2.0		3	3
1022	7	height	高度/mm	number	t	2.0		3	4
1023	7	span	支点距/mm	number	t	20.0		3	5
1024	7	speed	速度/mm/min	number	t	1.0		3	6
1025	7	fmax	Fmax/N	number	t			3	7
1026	7	stress_02	0.2%规定非比例弯曲应力/MPa	number	t			3	8
1027	7	curve_no	曲线/数据文件编号	text	t			3	9
1028	7	sample_state	试样状态	select	t	完整|断裂|异常		3	10
1029	7	conclusion	单样结论	calc	t		{"column_key": "conclusion", "op": "ge", "inputs": ["stress_02"], "args": {"constant": 800, "true_value": "符合", "false_value": "不符合"}}	3	11
1030	7	note	备注	text	t			3	12
1031	8	sample_no	样品编号	text	t			3	1
1032	8	face	测量方向	text	t			3	2
1033	8	indent1	压痕1/HV	number	t			3	3
1034	8	indent2	压痕2/HV	number	t			3	4
1035	8	indent3	压痕3/HV	number	t			3	5
1036	8	mean	测试面平均/HV	calc	t		{"column_key": "mean", "op": "avg", "inputs": ["indent1", "indent2", "indent3"], "args": {"precision": 1}}	3	6
1037	8	indent_quality	压痕有效性	select	t	有效|无效		3	7
1038	8	image_no	压痕图像编号	text	t			3	8
1039	8	note	备注	text	t			3	9
1040	9	sample_no	试样编号	text	t			3	1
1041	9	r1_fixed_p1	重复1·固定端P1/mm	number	t			3	2
1042	9	r1_fixed_p2	重复1·固定端P2/mm	number	t			3	3
1043	9	r1_fixed_p3	重复1·固定端P3/mm	number	t			3	4
1044	9	r1_middle_p1	重复1·中点P1/mm	number	t			3	5
1045	9	r1_middle_p2	重复1·中点P2/mm	number	t			3	6
1046	9	r1_middle_p3	重复1·中点P3/mm	number	t			3	7
1047	9	r1_free_p1	重复1·自由端P1/mm	number	t			3	8
1048	9	r1_free_p2	重复1·自由端P2/mm	number	t			3	9
1049	9	r1_free_p3	重复1·自由端P3/mm	number	t			3	10
1050	9	fixed_mean	固定端总平均/mm	calc	t		{"column_key": "fixed_mean", "op": "avg", "inputs": ["r1_fixed_p1", "r1_fixed_p2", "r1_fixed_p3"], "args": {"precision": 4}}	3	11
1051	9	middle_mean	中点总平均/mm	calc	t		{"column_key": "middle_mean", "op": "avg", "inputs": ["r1_middle_p1", "r1_middle_p2", "r1_middle_p3"], "args": {"precision": 4}}	3	12
1052	9	free_mean	自由端总平均/mm	calc	t		{"column_key": "free_mean", "op": "avg", "inputs": ["r1_free_p1", "r1_free_p2", "r1_free_p3"], "args": {"precision": 4}}	3	13
1053	9	mean	试样总平均/mm	calc	t		{"column_key": "mean", "op": "avg", "inputs": ["r1_fixed_p1", "r1_fixed_p2", "r1_fixed_p3", "r1_middle_p1", "r1_middle_p2", "r1_middle_p3", "r1_free_p1", "r1_free_p2", "r1_free_p3"], "args": {"precision": 4}}	3	14
1054	9	deviation	尺寸偏差/mm	calc	t			3	15
1055	9	limit	判定要求/mm	text	t			3	16
1056	9	conclusion	单样结论	text	t			3	17
1057	9	image_no	图像编号	text	t			3	18
1058	9	note	备注	text	t			3	19
1059	10	sample_no	试样编号	text	f			3	0
1060	10	control_no	对照试样编号	text	f			3	1
1061	10	shape	试样形状	select:圆片|牙形|其他	f	圆片		3	2
1062	10	size	试样尺寸	text	f			3	3
1063	10	cover_method	遮盖方式	select:试样夹|锡箔|铝箔	f	试样夹		3	4
1064	10	cover_direction	遮盖区域/方向	text	f			3	5
1065	10	cover_secure	遮盖是否牢固	select:是|否	f	是		3	6
1066	10	position	摆放位置	text	f			3	7
1067	10	photo_no	照射前/后照片编号	text	f			3	8
1068	10	observer1	观察者1结果	select:未见明显差异|轻微差异|明显差异|无法判定	f	未见明显差异		3	9
1069	10	observer2	观察者2结果	select:未见明显差异|轻微差异|明显差异|无法判定	f	未见明显差异		3	10
1070	10	observer3	观察者3结果	select:未见明显差异|轻微差异|明显差异|无法判定	f	未见明显差异		3	11
1071	10	overall	总体观察结果	calc	f		{"column_key":"overall","op":"color_overall","inputs":["observer1","observer2","observer3"],"args":{}}	3	12
1072	10	conclusion	单样结论	calc	f		{"column_key":"conclusion","op":"color_conclusion","inputs":["observer1","observer2","observer3"],"args":{}}	3	13
1073	10	note	备注	text	f			3	14
1074	11	sample_no	样品编号	text	t			3	1
1075	11	unit_name	牙位	text	t			3	2
1076	11	surface_check	表面检查	select	t	合格|不合格		3	3
1077	11	margin_gap	边缘间隙/μm	number	t			3	4
1078	11	roughness	粗糙度Ra/μm	number	t			3	5
1079	11	porosity	孔隙度/%	number	t			3	6
1080	11	conclusion	单样结论	calc	t			3	7
1081	11	note	备注	text	t			3	8
1082	12	sample_no	样品编号	text	t			3	1
1083	12	check_item	检查项目	text	t			3	2
1084	12	result	结果	select	t	合格|不合格		3	3
1085	12	conclusion	单样结论	calc	t			3	4
1086	12	note	备注	text	t			3	5
1087	13	sample_no	试样编号	text	t			3	1
1088	13	a1	测量1空气中质量A/g	number	t			3	2
1089	13	b1	测量1水中表观质量B/g	number	t			3	3
1090	13	water_temp1	测量1水温/℃	number	t			3	4
1091	13	water_density1	测量1水密度/(g/cm³)	number	t			3	5
1092	13	auto_density1	测量1天平密度	number	t			3	6
1093	13	density1	测量1复算密度	calc	t			3	7
1094	13	a2	测量2空气中质量A/g	number	t			3	8
1095	13	b2	测量2水中表观质量B/g	number	t			3	9
1096	13	water_temp2	测量2水温/℃	number	t			3	10
1097	13	water_density2	测量2水密度/(g/cm³)	number	t			3	11
1098	13	auto_density2	测量2天平密度	number	t			3	12
1099	13	density2	测量2复算密度	calc	t			3	13
1100	13	a3	测量3空气中质量A/g	number	t			3	14
1101	13	b3	测量3水中表观质量B/g	number	t			3	15
1102	13	water_temp3	测量3水温/℃	number	t			3	16
1103	13	water_density3	测量3水密度/(g/cm³)	number	t			3	17
1104	13	auto_density3	测量3天平密度	number	t			3	18
1105	13	density3	测量3复算密度	calc	t			3	19
1106	13	density_difference	最大密度差/(g/cm³)	calc	t			3	20
1107	13	mean	平均密度/(g/cm³)	calc	t			3	21
1108	13	relative_deviation	相对偏差/%	calc	t			3	22
1109	13	conclusion	单样结论	calc	t			3	23
1110	13	data_file_no	数据文件编号	text	t			3	24
1111	13	note	备注	text	t			3	25
1112	14	sample_no	试样编号	text	t			3	1
1113	14	specimen_role	试样用途	select	t	浸泡试样|未浸泡对照		3	2
1114	14	diameter	直径/mm	number	t			3	3
1115	14	thickness	厚度/mm	number	t			3	4
1116	14	surface_prep	表面制备	select	t	符合|不符合		3	5
1117	14	color_change	颜色变化	select	t	无|极轻微|明显		3	6
1118	14	tarnish_product	晦暗产物	select	t	无|有		3	7
1119	14	removal_ease	轻柔刷洗/擦拭去除性	select	t	易去除|不易去除|不适用		3	8
1120	14	reflectance_change	反射率变化（仅报告）	text	t			3	9
1121	14	conclusion	单样结论	calc	t			3	10
1122	14	note	备注	text	t			3	11
1195	1	sample_no	试样编号	text	f			3	0
1196	1	surface_confirm	原打印面/方向确认	select:符合|不符合	f	符合		3	1
1197	1	position	测量位置	text	f	Z轴		3	2
1198	1	ra1	Ra1/μm	number	f			3	3
1199	1	ra2	Ra2/μm	number	f			3	4
1200	1	ra3	Ra3/μm	number	f			3	5
1201	1	mean	平均值/μm	calc	f		{"column_key":"mean","op":"avg","inputs":["ra1","ra2","ra3"],"args":{"precision":3}}	3	6
1202	1	limit	判定限值/μm	number	f	15		3	7
1203	1	conclusion	单样结论	calc	f		{"column_key":"conclusion","op":"le","inputs":["mean","limit"],"args":{"constant":15,"true_value":"符合","false_value":"不符合"}}	3	8
1204	1	retest_mean	复测后平均/μm	number	f			3	9
1205	1	file_no	曲线/数据文件编号	text	f			3	10
1206	1	note	备注	text	f			3	11
\.


--
-- Data for Name: experiment_config_equipment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experiment_config_equipment (config_id, management_no, binding_role, required, sort_order, note, created_at, updated_at) FROM stdin;
17	BPGL-A036	主设备	t	0	触针式粗糙度测量	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
17	BPGL-B001	标准器	t	1	使用前标准块核查	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
17	BPGL-A009	环境监测	f	2	记录温度和相对湿度	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
17	BPGL-A010	环境监测	f	3	记录温度和相对湿度	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
17	BPGL-A011	环境监测	f	4	记录温度和相对湿度	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
17	BPGL-A013	环境监测	f	5	记录温度和相对湿度	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
17	BPGL-A014	环境监测	f	6	记录温度和相对湿度	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
17	BPGL-A015	环境监测	f	7	记录温度和相对湿度	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
17	BPGL-A016	环境监测	f	8	记录温度和相对湿度	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
17	BPGL-A040	测量平台	t	9	00级大理石平台，用于粗糙度仪及小试样稳定放置	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
17	BPGL-A041	水平确认	t	10	确认平台及测量方向水平状态	2026-08-18 14:33:46.792268+08	2026-08-18 14:33:46.792268+08
3	BPGL-A033	成像设备	t	0	影像输出	2026-08-19 11:50:08.342794+08	2026-08-19 11:50:08.342794+08
3	BPGL-B005	标准器	t	1	密度计核查	2026-08-19 11:50:08.342794+08	2026-08-19 11:50:08.342794+08
3	BPGL-A011	环境监测	f	2	记录温度和相对湿度	2026-08-19 11:50:08.342794+08	2026-08-19 11:50:08.342794+08
3	BPGL-A029	测量设备	t	3	黑白密度测量	2026-08-19 11:50:08.342794+08	2026-08-19 11:50:08.342794+08
3	BPGL-A032	主设备	t	4	X射线限束与曝光	2026-08-19 11:50:08.342794+08	2026-08-19 11:50:08.342794+08
3	BPGL-B024	primary	t	5		2026-08-19 11:50:08.342794+08	2026-08-19 11:50:08.342794+08
3	BPGL-B018	primary	t	6		2026-08-19 11:50:08.342794+08	2026-08-19 11:50:08.342794+08
3	BPGL-B017	primary	t	7		2026-08-19 11:50:08.342794+08	2026-08-19 11:50:08.342794+08
18	BPGL-A021	主设备	t	1	加载与力值采集	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
18	BPGL-B009	夹具	t	2	金属-陶瓷结合试验专用夹具	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
18	BPGL-A001	辅助量具	t	3	跨距、宽度等尺寸测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
18	BPGL-A009	环境监测	f	4	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
18	BPGL-A010	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
18	BPGL-A011	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
18	BPGL-A012	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
18	BPGL-A013	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
18	BPGL-A014	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
18	BPGL-A015	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
18	BPGL-A016	环境监测	f	11	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A033	成像设备	t	1	影像输出	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-B005	标准器	t	2	密度计核查	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-B006	辅助器具	f	3	统一成像/观察背景	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-C001	安全监测	t	4	辐射安全监测	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-C002	外观检查	f	5	影像/样品辅助观察	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-C003	外观检查	f	6	影像/样品辅助观察	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A001	辅助量具	f	7	尺寸与摆位确认	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A005	辅助量具	f	8	厚度复核	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A009	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A010	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A011	环境监测	f	11	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A012	环境监测	f	12	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A013	环境监测	f	13	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A014	环境监测	f	14	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A015	环境监测	f	15	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A016	环境监测	f	16	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A027	清洗设备	f	17	样品清洁	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A029	测量设备	t	18	黑白密度测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
19	BPGL-A032	主设备	t	19	X射线限束与曝光	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A026	主设备	t	1	H1、H2影像测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-B012	夹具	t	2	翘曲变形切割定位	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A001	辅助量具	f	3	试样尺寸确认	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A009	环境监测	f	4	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A010	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A011	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A012	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A013	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A014	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A015	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A016	环境监测	f	11	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
20	BPGL-A018	制样设备	t	12	切割悬臂试样	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A020	主设备	t	1	热膨胀曲线与系数测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A034	温度测量	t	2	温度系统核查	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A001	辅助量具	t	3	试样长度测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A004	备用量具	f	4	特殊形状尺寸备用测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A009	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A010	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A011	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A012	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A013	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A014	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A015	环境监测	f	11	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A016	环境监测	f	12	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A027	清洗设备	f	13	试样清洁	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
21	BPGL-A030	制样设备	f	14	试样干燥	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A034	温度测量	t	1	烘箱、冰水和冷却温度确认	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-C002	外观检查	t	2	10倍检查裂纹、崩瓷和破裂	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A009	环境监测	f	3	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A010	环境监测	f	4	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A011	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A012	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A013	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A014	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A015	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A016	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A028	光照设备	t	11	检查区域光照	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A030	主设备	t	12	100±2℃加热	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
3	BPGL-B016	primary	t	8		2026-08-19 11:50:08.342794+08	2026-08-19 11:50:08.342794+08
22	BPGL-A037	计时设备	t	13	YS-860电子秒表；两块分别用于加热/转移与浸泡计时	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A038	计时设备	t	14	YS-860电子秒表；两块分别用于加热/转移与浸泡计时	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
22	BPGL-A039	光照确认	f	15	检查区域照度确认	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A021	主设备	t	1	加载与力值采集	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A023	位移测量	t	2	挠度测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-B008	夹具	t	3	三点弯曲加载	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A001	辅助量具	t	4	试样尺寸和跨距测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A009	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A010	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A011	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A012	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A013	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A014	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A015	环境监测	f	11	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
23	BPGL-A016	环境监测	f	12	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A035	主设备	t	1	HV10试验	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A036	表面确认	f	2	测试面粗糙度实测	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-B007	标准器	t	3	标准硬度块核查	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A009	环境监测	f	4	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A010	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A011	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A012	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A013	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A014	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A015	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A016	环境监测	f	11	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
24	BPGL-A019	制样设备	f	12	测试面磨抛	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
25	BPGL-A026	主设备	t	1	二次元影像法厚度测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
25	BPGL-A009	环境监测	f	2	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
29	BPGL-A034	温度测量	t	1	试验用水温度测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
29	BPGL-A042	主设备	t	2	空气中质量、水中表观质量和自动密度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
29	BPGL-B013	标准器	t	3	天平核查砝码	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
29	BPGL-B014	标准器	f	4	备用核查砝码	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
29	BPGL-B023	标准器	t	5	密度系统核查	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
29	BPGL-A027	清洗设备	t	6	试样超声清洗2 min	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
30	BPGL-A025	称量设备	t	1	水合硫化钠称量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
30	BPGL-C006	溶液配制	t	2	1000 mL溶液定容	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
30	BPGL-A043	主设备	t	3	每分钟浸入10～15 s，连续运行72±1 h	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
30	BPGL-A017	恒温设备	t	4	维持23±2 ℃	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
30	BPGL-A019	制样设备	t	5	1 μm终抛前的金相研磨抛光	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
30	BPGL-A027	清洗设备	t	6	乙醇中超声清洗2 min	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
30	BPGL-C012	安全设施	t	7	硫化钠溶液配制与操作防护	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
30	BPGL-A039	光照确认	t	8	观察位置照度≥1000 lx	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
1	BPGL-A036	主设备	t	0	触针式粗糙度测量	2026-08-19 10:32:08.082383+08	2026-08-19 10:32:08.082383+08
1	BPGL-B001	标准器	t	1	使用前标准块核查	2026-08-19 10:32:08.082383+08	2026-08-19 10:32:08.082383+08
1	BPGL-A009	环境监测	t	2	记录温度和相对湿度	2026-08-19 10:32:08.082383+08	2026-08-19 10:32:08.082383+08
1	BPGL-A040	测量平台	t	3	00级大理石平台，用于粗糙度仪及小试样稳定放置	2026-08-19 10:32:08.082383+08	2026-08-19 10:32:08.082383+08
1	BPGL-A041	水平确认	t	4	确认平台及测量方向水平状态	2026-08-19 10:32:08.082383+08	2026-08-19 10:32:08.082383+08
26	BPGL-A024	主设备	t	0	耐光色稳定性试验	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A025	称量设备	t	1	试剂/溶液配制	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A034	温度测量	t	2	水浴温度核查	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-B003	标准器	t	3	牙色比色参考	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-B006	辅助器具	t	4	统一观察背景	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A009	环境监测	f	5	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A010	环境监测	f	6	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A011	环境监测	f	7	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A012	环境监测	f	8	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A013	环境监测	f	9	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A014	环境监测	f	10	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A015	环境监测	f	11	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A016	环境监测	f	12	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A028	光照设备	t	13	D65标准光源对色	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A031	测量设备	t	14	试验溶液pH确认	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-B004	标准器	f	15	基托材料比色参考	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
26	BPGL-A039	光照确认	t	16	D65对色灯箱及观察区域照度确认	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
4	BPGL-A026	主设备	t	1	H1、H2影像测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-B012	夹具	t	2	翘曲变形切割定位	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-A001	辅助量具	f	3	试样尺寸确认	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-A009	环境监测	f	4	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-A010	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-A011	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-A012	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-A013	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-A014	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-A015	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-A016	环境监测	f	11	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
4	BPGL-A018	制样设备	t	12	切割悬臂试样	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A020	主设备	t	1	热膨胀曲线与系数测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A034	温度测量	t	2	温度系统核查	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A001	辅助量具	t	3	试样长度测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A004	备用量具	f	4	特殊形状尺寸备用测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A009	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A010	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A011	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A012	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A013	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A014	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A015	环境监测	f	11	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A016	环境监测	f	12	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A027	清洗设备	f	13	试样清洁	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
5	BPGL-A030	制样设备	f	14	试样干燥	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A034	温度测量	t	1	烘箱、冰水和冷却温度确认	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-C002	外观检查	t	2	10倍检查裂纹、崩瓷和破裂	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A009	环境监测	f	3	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A010	环境监测	f	4	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A011	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A012	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A013	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A014	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A015	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A016	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A028	光照设备	t	11	检查区域光照	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A030	主设备	t	12	100±2℃加热	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A037	计时设备	t	13	YS-860电子秒表；两块分别用于加热/转移与浸泡计时	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A038	计时设备	t	14	YS-860电子秒表；两块分别用于加热/转移与浸泡计时	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
6	BPGL-A039	光照确认	f	15	检查区域照度确认	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A021	主设备	t	1	加载与力值采集	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A023	位移测量	t	2	挠度测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-B008	夹具	t	3	三点弯曲加载	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A001	辅助量具	t	4	试样尺寸和跨距测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A009	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A010	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A011	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A012	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A013	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A014	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A015	环境监测	f	11	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
7	BPGL-A016	环境监测	f	12	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A035	主设备	t	1	HV10试验	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A036	表面确认	f	2	测试面粗糙度实测	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-B007	标准器	t	3	标准硬度块核查	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A009	环境监测	f	4	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A010	环境监测	f	5	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A011	环境监测	f	6	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A012	环境监测	f	7	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A013	环境监测	f	8	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A014	环境监测	f	9	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A015	环境监测	f	10	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A016	环境监测	f	11	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
8	BPGL-A019	制样设备	f	12	测试面磨抛	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
9	BPGL-A026	主设备	t	1	二次元影像法厚度测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
9	BPGL-A009	环境监测	f	2	记录温度和相对湿度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
10	BPGL-A024	主设备	t	0	耐光色稳定性试验	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A025	称量设备	t	1	试剂/溶液配制	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A034	温度测量	t	2	水浴温度核查	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-B003	标准器	t	3	牙色比色参考	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-B006	辅助器具	t	4	统一观察背景	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A009	环境监测	f	5	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A010	环境监测	f	6	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A011	环境监测	f	7	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A012	环境监测	f	8	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A013	环境监测	f	9	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A014	环境监测	f	10	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A015	环境监测	f	11	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A016	环境监测	f	12	记录温度和相对湿度	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A028	光照设备	t	13	D65标准光源对色	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A031	测量设备	t	14	试验溶液pH确认	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-B004	标准器	f	15	基托材料比色参考	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
10	BPGL-A039	光照确认	t	16	D65对色灯箱及观察区域照度确认	2026-08-18 13:08:07.345323+08	2026-08-18 13:08:07.345323+08
13	BPGL-A034	温度测量	t	1	试验用水温度测量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
13	BPGL-A042	主设备	t	2	空气中质量、水中表观质量和自动密度	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
13	BPGL-B013	标准器	t	3	天平核查砝码	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
13	BPGL-B014	标准器	f	4	备用核查砝码	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
13	BPGL-B023	标准器	t	5	密度系统核查	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
13	BPGL-A027	清洗设备	t	6	试样超声清洗2 min	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
14	BPGL-A025	称量设备	t	1	水合硫化钠称量	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
14	BPGL-C006	溶液配制	t	2	1000 mL溶液定容	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
14	BPGL-A043	主设备	t	3	每分钟浸入10～15 s，连续运行72±1 h	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
14	BPGL-A017	恒温设备	t	4	维持23±2 ℃	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
14	BPGL-A019	制样设备	t	5	1 μm终抛前的金相研磨抛光	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
14	BPGL-A027	清洗设备	t	6	乙醇中超声清洗2 min	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
14	BPGL-C012	安全设施	t	7	硫化钠溶液配制与操作防护	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
14	BPGL-A039	光照确认	t	8	观察位置照度≥1000 lx	2026-08-14 16:53:45.327149+08	2026-08-14 16:53:45.327149+08
2	BPGL-A021	主设备	t	0	加载与力值采集	2026-08-19 10:51:47.381338+08	2026-08-19 10:51:47.381338+08
2	BPGL-B009	夹具	t	1	金属-陶瓷结合试验专用夹具	2026-08-19 10:51:47.381338+08	2026-08-19 10:51:47.381338+08
2	BPGL-A001	辅助量具	t	2	跨距、宽度等尺寸测量	2026-08-19 10:51:47.381338+08	2026-08-19 10:51:47.381338+08
2	BPGL-A009	环境监测	f	3	记录温度和相对湿度	2026-08-19 10:51:47.381338+08	2026-08-19 10:51:47.381338+08
\.


--
-- Data for Name: experiment_config_fields; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experiment_config_fields (id, config_id, section_title, section_order, field_key, field_label, field_type, field_default, field_options, is_required, is_readonly, is_actual, sort_order) FROM stdin;
3835	17	环境与设备	1	test_date	检测日期	date		[]	f	f	f	0
3836	17	试验参数与使用前确认	2	standard_block	标准粗糙度样板编号	text	BPGL-B001	[]	f	f	f	0
3837	17	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
3838	17	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
3839	17	环境与设备	1	temperature_before	检测前温度/℃	number	23	[]	f	f	f	0
3840	17	试验参数与使用前确认	2	standard_block_nominal	标准样板标称值/μm	number	3	[]	f	f	f	0
3841	17	试验参数与使用前确认	2	repeat_check_1	标准样板实测值1/μm	number		[]	f	f	f	0
3842	17	环境与设备	1	temperature_after	检测后温度/℃	number	23	[]	f	f	f	0
3843	17	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	["符合","不符合"]	f	f	f	0
3844	17	环境与设备	1	humidity_before	检测前湿度/%RH	number	50	[]	f	f	f	0
3845	17	试验参数与使用前确认	2	repeat_check_2	标准样板实测值2/μm	number		[]	f	f	f	0
3846	17	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
3847	17	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	["已核对且在有效期内","存在异常"]	f	f	f	0
3848	17	环境与设备	1	humidity_after	检测后湿度/%RH	number	50	[]	f	f	f	0
3849	17	试验参数与使用前确认	2	repeat_check_3	标准样板实测值3/μm	number		[]	f	f	f	0
3850	17	环境与设备	1	detection_location	检测地点	text		[]	f	t	f	0
3851	17	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text		[]	f	t	f	0
3852	17	试验参数与使用前确认	2	standard_block_result	标准样板核查结果	select		["合格","不合格"]	f	f	f	0
3853	17	试验参数与使用前确认	2	calculation_standard	计算标准	text	ISO-97	[]	f	f	f	0
3854	17	环境与设备	1	start_time	实验开始时间	datetime		[]	f	f	f	0
3855	17	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认	[]	f	f	f	0
3856	17	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	["一致","存在偏离"]	f	f	f	0
3857	17	环境与设备	1	end_time	实验结束时间	datetime		[]	f	f	f	0
3858	17	试验参数与使用前确认	2	shape_removal	形状去除	text	自动	[]	f	f	f	0
3859	17	试验参数与使用前确认	2	filter_type	滤波器	text	高斯	[]	f	f	f	0
3860	17	母版补充现场观察	3	z_axis_marking	Z轴正方向标识	select	清晰	["清晰","不清晰"]	f	f	f	0
3861	17	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	["无明显干扰","有干扰"]	f	f	f	0
3862	17	母版补充现场观察	3	surface_cleaning_actual	测试面清洁状态	select	清洁	["清洁","不清洁"]	f	f	f	0
3863	17	试验参数与使用前确认	2	lambda_s	λs	text	自动	[]	f	f	f	0
3864	17	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
3865	17	母版补充现场观察	3	fixture_stability	试样固定及工作台稳定性	select	符合	["符合","不符合"]	f	f	f	0
3866	17	环境与设备	1	software	软件名称/版本	text		[]	f	f	f	0
3867	17	试验参数与使用前确认	2	measurement_range	测量范围/μm	number	40	[]	f	f	f	0
3868	17	母版补充现场观察	3	measurement_line_note	实际测量线/方向说明	text	按受控方法规定位置测量	[]	f	f	f	0
3869	17	试验参数与使用前确认	2	sampling_length	取样长度/mm	number	0.8	[]	f	f	f	0
3870	17	环境与设备	1	data_path	仪器原始数据保存路径	text		[]	f	f	f	0
3871	17	试验参数与使用前确认	2	sampling_count	取样个数	number	5	[]	f	f	f	0
3872	17	环境与设备	1	equipment_name	主要设备名称	text		[]	f	t	f	0
3873	17	环境与设备	1	equipment_model	设备型号/规格	text		[]	f	t	f	0
3874	17	试验参数与使用前确认	2	evaluation_length	评定长度/mm	number	4	[]	f	f	f	0
3875	17	试验参数与使用前确认	2	measuring_speed	测量速度/mm/s	number	0.5	[]	f	f	f	0
3876	17	环境与设备	1	equipment_no	设备管理编号	text		[]	f	t	f	0
3877	17	环境与设备	1	calibration_certificate	校准/检定证书编号	text		[]	f	t	f	0
3878	17	试验参数与使用前确认	2	cutoff_filter	滤波/计算标准	text	高斯	[]	f	f	f	0
3879	17	环境与设备	1	calibration_due	台账校准时间	text		[]	f	t	f	0
3880	17	试验参数与使用前确认	2	probe_condition	探针状态	select		["正常","异常"]	f	f	f	0
3881	17	环境与设备	1	equipment_status	使用前设备状态	select		["正常","异常"]	f	f	f	0
3882	17	试验参数与使用前确认	2	platform_level	工作台水平状态	select		["符合","不符合"]	f	f	f	0
3883	17	试验参数与使用前确认	2	surface_state	试样表面状态	select		["原打印表面","经处理表面","其他"]	f	f	f	0
3884	17	试验参数与使用前确认	2	measurement_direction	测量方向/线位	text	3条平行、不重叠、代表性测量线	[]	f	f	f	0
3885	17	试验参数与使用前确认	2	three_length_mode	评定长度方式	select	5L（默认）	["5L（默认）","3L（已完成方法确认）"]	f	f	f	0
4221	2	环境与设备	1	test_date	检测日期	date		[]	f	f	f	0
4222	2	裂纹萌生试验参数	2	fixture_no	金瓷结合试验夹具编号	text	BPGL-B009	[]	f	f	f	0
4223	2	母版补充现场观察	3	temperature_before	本次温度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
4224	2	裂纹萌生试验参数	2	support_span	支承跨距/mm	number	20	[]	f	f	f	0
4225	2	环境与设备	1	temperature_before	检测前温度/℃	number	23	[]	f	f	f	0
4226	2	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
4227	2	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	["符合","不符合"]	f	f	f	0
4228	2	环境与设备	1	temperature_after	检测后温度/℃	number	23	[]	f	f	f	0
4229	2	裂纹萌生试验参数	2	roller_radius	压头/支点半径R/mm	number	1	[]	f	f	f	0
4230	2	环境与设备	1	humidity_before	检测前湿度/%RH	number	50	[]	f	f	f	0
4231	2	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
4232	2	裂纹萌生试验参数	2	parallel_block_no	平行块编号	text	BGGL-B019	[]	f	f	f	0
4233	2	环境与设备	1	humidity_after	检测后湿度/%RH	number	50	[]	f	f	f	0
4234	2	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	["已核对且在有效期内","存在异常"]	f	f	f	0
4235	2	裂纹萌生试验参数	2	parallel_block_parallelism	平行块平行度/mm	number		[]	f	f	f	0
4236	2	环境与设备	1	detection_location	检测地点	text		[]	f	t	f	0
4237	2	裂纹萌生试验参数	2	loading_speed	加载速度/mm/min	number	1.5	[]	f	f	f	0
4238	2	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认	[]	f	f	f	0
4239	2	母版补充现场观察	3	centering_confirmation	试样居中及跨距确认	select	符合	["符合","不符合"]	f	f	f	0
4240	2	环境与设备	1	start_time	实验开始时间	datetime		[]	f	f	f	0
4241	2	裂纹萌生试验参数	2	observation_method	裂纹萌生观察方式	select	目视	["声响","目视"]	f	f	f	0
4242	2	环境与设备	1	end_time	实验结束时间	datetime		[]	f	f	f	0
4243	2	裂纹萌生试验参数	2	parallel_check	夹具平行与居中确认	select		["符合","不符合"]	f	f	f	0
4244	2	母版补充现场观察	3	crack_observation_note	裂纹萌生/陶瓷剥离观察说明	text	按声响或目视结果判定	[]	f	f	f	0
4245	2	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	["无明显干扰","有干扰"]	f	f	f	0
4246	2	裂纹萌生试验参数	2	metal_name	试样名称	text		[]	f	t	f	0
4247	2	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
4248	2	裂纹萌生试验参数	2	metal_batch	批号	text		[]	f	t	f	0
4249	2	环境与设备	1	software	软件名称/版本	text		[]	f	f	f	0
4250	2	裂纹萌生试验参数	2	em_source	杨氏模量来源	select	说明书	["说明书","检测报告","注册资料","质保书","其他"]	f	f	f	0
4251	2	裂纹萌生试验参数	2	em_source_file	杨氏模量来源文件编号	text		[]	f	f	f	0
4252	2	环境与设备	1	data_path	仪器原始数据保存路径	text		[]	f	f	f	0
4253	2	环境与设备	1	equipment_name	主要设备名称	text		[]	f	t	f	0
4254	2	裂纹萌生试验参数	2	orientation	试样放置方向	select		["金属面朝上、陶瓷面朝下","其他"]	f	f	f	0
4255	2	环境与设备	1	equipment_model	设备型号/规格	text		[]	f	t	f	0
4256	2	环境与设备	1	equipment_no	设备管理编号	text		[]	f	t	f	0
4257	2	环境与设备	1	calibration_certificate	校准/检定证书编号	text		[]	f	t	f	0
4258	2	环境与设备	1	calibration_due	台账校准时间	text		[]	f	t	f	0
4259	2	环境与设备	1	equipment_status	使用前设备状态	select		["正常","异常"]	f	f	f	0
4734	3	辐射安全与曝光参数	2	radiation_safety	辐射安全确认	select		["允许曝光","禁止曝光"]	f	f	f	0
4735	3	环境与设备	1	test_date	检测日期	date		[]	f	f	f	0
4736	3	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
4737	3	辐射安全与曝光参数	2	xray_model	X射线机型号/编号	text	BPGL-A032	[]	f	f	f	0
4738	3	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
4739	3	环境与设备	1	temperature_before	检测前温度/℃	number	23	[]	f	f	f	0
4740	3	环境与设备	1	temperature_after	检测后温度/℃	number	23	[]	f	f	f	0
4741	3	辐射安全与曝光参数	2	panel_no	数据采集板编号	text	BPGL-B024	[]	f	f	f	0
4742	3	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	["符合","不符合"]	f	f	f	0
4743	3	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
4744	3	环境与设备	1	humidity_before	检测前湿度/%RH	number	50	[]	f	f	f	0
4745	3	辐射安全与曝光参数	2	iqi_no	孔形像质计编号	text	BPGL-B016;BPGL-B017;BPGL-B018	[]	f	f	f	0
4746	3	环境与设备	1	humidity_before	检测后湿度/%RH	number	50	[]	f	f	f	0
4747	3	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	["已核对且在有效期内","存在异常"]	f	f	f	0
4748	3	辐射安全与曝光参数	2	density_meter_no	密度计/标准密度片编号	text	BPGL-A029;BPGL-B005	[]	f	f	f	0
4749	3	环境与设备	1	detection_location	检测地点	text		[]	f	t	f	0
4750	3	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text		[]	f	t	f	0
4751	3	辐射安全与曝光参数	2	density_nominal	标准密度片标称值	number		[]	f	f	f	0
4752	3	环境与设备	1	start_time	实验开始时间	datetime		[]	f	f	f	0
4753	3	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认	[]	f	f	f	0
4754	3	辐射安全与曝光参数	2	density_measured_1	标准密度片实测值1	number		[]	f	f	f	0
4755	3	环境与设备	1	end_time	实验结束时间	datetime		[]	f	f	f	0
4756	3	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	["一致","存在偏离"]	f	f	f	0
4757	3	辐射安全与曝光参数	2	density_measured_2	标准密度片实测值2	number		[]	f	f	f	0
4758	3	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	["无明显干扰","有干扰"]	f	f	f	0
4759	3	辐射安全与曝光参数	2	density_measured_3	标准密度片实测值3	number		[]	f	f	f	0
4760	3	母版补充现场观察	3	sample_surface_xray	样品表面清洁、干燥状态	select	符合	["符合","不符合"]	f	f	f	0
4761	3	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
4762	3	辐射安全与曝光参数	2	tube_voltage	管电压/kV	number	72	[]	f	f	f	0
4763	3	母版补充现场观察	3	radiation_zone_clear	辐射区域无无关人员及物品	select	符合	["符合","不符合"]	f	f	f	0
4764	3	环境与设备	1	software	软件名称/版本	text		[]	f	f	f	0
4765	3	母版补充现场观察	3	panel_iqi_position_confirmation	探测板、像质计与样品位置确认	select	符合	["符合","不符合"]	f	f	f	0
4766	3	辐射安全与曝光参数	2	tube_current	管电流/mA	number	14	[]	f	f	f	0
4767	3	辐射安全与曝光参数	2	exposure_time	曝光时间/ms	number	71	[]	f	f	f	0
4768	3	母版补充现场观察	3	operator_authorization	X射线操作授权确认	select	已授权	["已授权","未授权"]	f	f	f	0
4769	3	环境与设备	1	data_path	仪器原始数据保存路径	text		[]	f	f	f	0
4770	3	母版补充现场观察	3	density_control_note	密度/灰度标准控制范围及核查说明	text	核查结果在受控范围内	[]	f	f	f	0
4771	3	环境与设备	1	equipment_name	主要设备名称	text		[]	f	t	f	0
4772	3	辐射安全与曝光参数	2	mas	管电流时间积/mAs	text	1	[]	f	f	f	0
4773	3	辐射安全与曝光参数	2	focus_mode	焦点模式	text	S	[]	f	f	f	0
4774	3	环境与设备	1	equipment_model	设备型号/规格	text		[]	f	t	f	0
4775	3	环境与设备	1	equipment_no	设备管理编号	text		[]	f	t	f	0
4776	3	辐射安全与曝光参数	2	orientation	样品摆放方向	text	咬合面朝下	[]	f	f	f	0
4777	3	辐射安全与曝光参数	2	exposure_count	曝光次数	number	1	[]	f	f	f	0
4778	3	环境与设备	1	calibration_certificate	校准/检定证书编号	text		[]	f	t	f	0
4779	3	环境与设备	1	calibration_due	台账校准时间	text		[]	f	t	f	0
4780	3	辐射安全与曝光参数	2	parameter_adjustment	参数调整情况	select	无调整	["无调整","有调整"]	f	f	f	0
4781	3	环境与设备	1	equipment_status	使用前设备状态	select		["正常","异常"]	f	f	f	0
4782	3	辐射安全与曝光参数	2	iqi_gray_01_1	像质计0.1 mm灰度·第1次	number		[]	f	f	f	0
4783	3	辐射安全与曝光参数	2	iqi_gray_01_2	像质计0.1 mm灰度·第2次	number		[]	f	f	f	0
4784	3	辐射安全与曝光参数	2	iqi_gray_01_3	像质计0.1 mm灰度·第3次	number		[]	f	f	f	0
4785	3	辐射安全与曝光参数	2	iqi_gray_02_1	像质计0.2 mm灰度·第1次	number		[]	f	f	f	0
4786	3	辐射安全与曝光参数	2	iqi_gray_02_2	像质计0.2 mm灰度·第2次	number		[]	f	f	f	0
4787	3	辐射安全与曝光参数	2	iqi_gray_02_3	像质计0.2 mm灰度·第3次	number		[]	f	f	f	0
4788	3	辐射安全与曝光参数	2	iqi_gray_03_1	像质计0.3 mm灰度·第1次	number		[]	f	f	f	0
4789	3	辐射安全与曝光参数	2	iqi_gray_03_2	像质计0.3 mm灰度·第2次	number		[]	f	f	f	0
4790	3	辐射安全与曝光参数	2	iqi_gray_03_3	像质计0.3 mm灰度·第3次	number		[]	f	f	f	0
4791	3	辐射安全与曝光参数	2	iqi_gray_04_1	像质计0.4 mm灰度·第1次	number		[]	f	f	f	0
3345	5	环境与设备	1	test_date	检测日期	date			f	f	f	1
4792	3	辐射安全与曝光参数	2	iqi_gray_04_2	像质计0.4 mm灰度·第2次	number		[]	f	f	f	0
4793	3	辐射安全与曝光参数	2	iqi_gray_04_3	像质计0.4 mm灰度·第3次	number		[]	f	f	f	0
4794	3	辐射安全与曝光参数	2	iqi_gray_05_1	像质计0.5 mm灰度·第1次	number		[]	f	f	f	0
4795	3	辐射安全与曝光参数	2	iqi_gray_05_2	像质计0.5 mm灰度·第2次	number		[]	f	f	f	0
4796	3	辐射安全与曝光参数	2	iqi_gray_05_3	像质计0.5 mm灰度·第3次	number		[]	f	f	f	0
4797	3	辐射安全与曝光参数	2	iqi_gray_06_1	像质计0.6 mm灰度·第1次	number		[]	f	f	f	0
4798	3	辐射安全与曝光参数	2	iqi_gray_06_2	像质计0.6 mm灰度·第2次	number		[]	f	f	f	0
4799	3	辐射安全与曝光参数	2	iqi_gray_06_3	像质计0.6 mm灰度·第3次	number		[]	f	f	f	0
4800	3	辐射安全与曝光参数	2	iqi_gray_07_1	像质计0.7 mm灰度·第1次	number		[]	f	f	f	0
4801	3	辐射安全与曝光参数	2	iqi_gray_07_2	像质计0.7 mm灰度·第2次	number		[]	f	f	f	0
4802	3	辐射安全与曝光参数	2	iqi_gray_07_3	像质计0.7 mm灰度·第3次	number		[]	f	f	f	0
4803	3	辐射安全与曝光参数	2	iqi_gray_08_1	像质计0.8 mm灰度·第1次	number		[]	f	f	f	0
4804	3	辐射安全与曝光参数	2	iqi_gray_08_2	像质计0.8 mm灰度·第2次	number		[]	f	f	f	0
4805	3	辐射安全与曝光参数	2	iqi_gray_08_3	像质计0.8 mm灰度·第3次	number		[]	f	f	f	0
4806	3	辐射安全与曝光参数	2	iqi_gray_09_1	像质计0.9 mm灰度·第1次	number		[]	f	f	f	0
4807	3	辐射安全与曝光参数	2	iqi_gray_09_2	像质计0.9 mm灰度·第2次	number		[]	f	f	f	0
4808	3	辐射安全与曝光参数	2	iqi_gray_09_3	像质计0.9 mm灰度·第3次	number		[]	f	f	f	0
4809	3	辐射安全与曝光参数	2	iqi_gray_10_1	像质计1.0 mm灰度·第1次	number		[]	f	f	f	0
4810	3	辐射安全与曝光参数	2	iqi_gray_10_2	像质计1.0 mm灰度·第2次	number		[]	f	f	f	0
4811	3	辐射安全与曝光参数	2	iqi_gray_10_3	像质计1.0 mm灰度·第3次	number		[]	f	f	f	0
4812	3	辐射安全与曝光参数	2	image_path	原始图像保存路径	text		[]	f	f	f	0
4133	1	环境与设备	1	test_date	检测日期	date		[]	f	f	f	0
4134	1	试验参数与使用前确认	2	standard_block	标准粗糙度样板编号	text	BPGL-B001	[]	f	f	f	0
4135	1	母版补充现场观察	3	temperature_before	本次温度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
4136	1	母版补充现场观察	3	humidity_before	本次湿度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
4137	1	环境与设备	1	temperature_before	检测前温度/℃	number	23	[]	f	f	f	0
4138	1	试验参数与使用前确认	2	standard_block_nominal	标准样板标称值/μm	number	1.61	[]	f	f	f	0
4139	1	试验参数与使用前确认	2	repeat_check_1	标准样板实测值1/μm	number		[]	f	f	f	0
4140	1	环境与设备	1	temperature_after	检测后温度/℃	number	23	[]	f	f	f	0
4141	1	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	["符合","不符合"]	f	f	f	0
4142	1	环境与设备	1	humidity_before	检测前湿度/%RH	number	50	[]	f	f	f	0
4143	1	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
4144	1	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	["已核对且在有效期内","存在异常"]	f	f	f	0
4145	1	环境与设备	1	humidity_before	检测后湿度/%RH	number	50	[]	f	f	f	0
4146	1	试验参数与使用前确认	2	repeat_check_3	标准样板实测值3/μm	number		[]	f	f	f	0
4147	1	环境与设备	1	detection_location	检测地点	text		[]	f	t	f	0
4148	1	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text		[]	f	t	f	0
4149	1	试验参数与使用前确认	2	standard_block_result	标准样板核查结果	select		["合格","不合格"]	f	f	f	0
4150	1	试验参数与使用前确认	2	calculation_standard	计算标准	text	ISO-97	[]	f	f	f	0
4151	1	环境与设备	1	start_time	实验开始时间	datetime		[]	f	f	f	0
4152	1	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认	[]	f	f	f	0
4153	1	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	["一致","存在偏离"]	f	f	f	0
4154	1	环境与设备	1	end_time	实验结束时间	datetime		[]	f	f	f	0
4155	1	试验参数与使用前确认	2	shape_removal	形状去除	text	自动	[]	f	f	f	0
4156	1	试验参数与使用前确认	2	filter_type	滤波器	text	高斯	[]	f	f	f	0
4157	1	母版补充现场观察	3	z_axis_marking	Z轴正方向标识	select	清晰	["清晰","不清晰"]	f	f	f	0
4158	1	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	["无明显干扰","有干扰"]	f	f	f	0
4159	1	母版补充现场观察	3	surface_cleaning_actual	测试面清洁状态	select	清洁	["清洁","不清洁"]	f	f	f	0
4160	1	试验参数与使用前确认	2	lambda_s	λs	text	自动	[]	f	f	f	0
4161	1	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
4162	1	母版补充现场观察	3	fixture_stability	试样固定及工作台稳定性	select	符合	["符合","不符合"]	f	f	f	0
4163	1	环境与设备	1	software	软件名称/版本	text		[]	f	f	f	0
4164	1	试验参数与使用前确认	2	measurement_range	测量范围/μm	number	40	[]	f	f	f	0
4165	1	母版补充现场观察	3	measurement_line_note	实际测量线/方向说明	text	按受控方法规定位置测量	[]	f	f	f	0
4166	1	试验参数与使用前确认	2	sampling_length	取样长度/mm	number	2.5	[]	f	f	f	0
4167	1	环境与设备	1	data_path	仪器原始数据保存路径	text		[]	f	f	f	0
4168	1	试验参数与使用前确认	2	sampling_count	取样个数	number	3	[]	f	f	f	0
4169	1	环境与设备	1	equipment_name	主要设备名称	text		[]	f	t	f	0
4170	1	环境与设备	1	equipment_model	设备型号/规格	text		[]	f	t	f	0
4171	1	试验参数与使用前确认	2	evaluation_length	评定长度/mm	number	7.5	[]	f	f	f	0
4172	1	试验参数与使用前确认	2	measuring_speed	测量速度/mm/s	number	1	[]	f	f	f	0
4173	1	环境与设备	1	equipment_no	设备管理编号	text		[]	f	t	f	0
4174	1	环境与设备	1	calibration_certificate	校准/检定证书编号	text		[]	f	t	f	0
4175	1	试验参数与使用前确认	2	cutoff_filter	滤波/计算标准	text	高斯	[]	f	f	f	0
4176	1	环境与设备	1	calibration_due	台账校准时间	text		[]	f	t	f	0
4177	1	环境与设备	1	equipment_status	使用前设备状态	select		["正常","异常"]	f	f	f	0
4178	1	试验参数与使用前确认	2	platform_level	工作台水平状态	select	符合	["符合","不符合"]	f	f	f	0
4179	1	试验参数与使用前确认	2	surface_state	试样表面状态	select		["原打印表面","经处理表面","其他"]	f	f	f	0
4180	1	试验参数与使用前确认	2	measurement_direction	测量方向/线位	text	3条平行、不重叠、代表性测量线	[]	f	f	f	0
4181	1	试验参数与使用前确认	2	three_length_mode	评定长度方式	select	3L（默认）	["5L（默认）","3L（已完成方法确认）"]	f	t	f	0
2278	19	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
2434	22	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
2480	23	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
2324	20	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
2359	21	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
2504	24	硬度和试样表面确认	2	sample_production_date	样品批号	text	\N		f	t	f	1
2547	25	影像测量参数	2	sample_production_date	样品批号	text	\N		t	t	f	1
2548	25	影像测量参数	2	production_date	生产日期	text	\N		t	t	f	2
2702	27	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
2736	28	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
2769	29	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
2812	30	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
3740	12	检验参数	2	contour_check	外形检查	select	合格	合格,不合格	f	f	f	3
3300	4	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
3301	4	环境与设备	1	test_date	检测日期	date			f	f	f	1
3302	4	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
3303	4	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
3304	4	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
3305	4	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
3306	4	环境与设备	1	detection_location	检测地点	text			f	t	f	6
3307	4	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
3308	4	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
3309	4	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
3310	4	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
3311	4	环境与设备	1	software	软件名称/版本	text			f	f	f	11
3312	4	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
3313	4	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
3314	4	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
3315	4	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
3316	4	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
3317	4	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
3318	4	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3319	4	测量和切割参数	2	image_device_no	二次元影像仪编号	text			f	f	f	1
3320	4	测量和切割参数	2	software_version	测量软件/版本	text			f	f	f	2
3321	4	测量和切割参数	2	cutting_device_no	切割设备编号	text			f	f	f	3
3322	4	测量和切割参数	2	fixture_no	专用试样夹具编号	text			f	f	f	4
3323	4	测量和切割参数	2	cutting_disc	切割片规格/批号	text			f	f	f	5
3324	4	测量和切割参数	2	measurement_function	测量功能	text	Point to Line		f	f	f	6
3325	4	测量和切割参数	2	baseline_before	切割前基准线确认	select		符合,不符合	f	f	f	7
3326	4	测量和切割参数	2	coolant	切割冷却液状态	select		持续供给,异常	f	f	f	8
3327	4	测量和切割参数	2	cut_position	切割位置/方向	text			f	f	f	9
3328	4	测量和切割参数	2	spindle_speed	主轴转速实设/显示	text			f	f	f	10
3329	4	测量和切割参数	2	cutting_stroke	切割行程	number	50.0		f	f	f	11
3330	4	测量和切割参数	2	feed_speed	进给速度	number	0.1		f	f	f	12
3331	4	测量和切割参数	2	baseline_after	切割后基准线确认	select		符合,不符合	f	f	f	13
3332	4	测量和切割参数	2	image_before_path	切割前原始图像路径	text			f	f	f	14
3333	4	测量和切割参数	2	image_after_path	切割后原始图像路径	text			f	f	f	15
3334	4	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
3335	4	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
3336	4	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3741	12	检验参数	2	adaptation	适合性	select	合格	合格,不合格	f	f	f	4
3337	4	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
3338	4	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3339	4	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
3340	4	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
3341	4	母版补充现场观察	3	baseline_actual	切割前基准线实际确认	select	清晰且符合	清晰且符合,不符合	f	f	t	9
3342	4	母版补充现场观察	3	cutting_position_note	实际切割位置及方向说明	text	按受控方法规定位置和方向切割		f	f	t	10
3343	4	母版补充现场观察	3	coolant_actual	切割过程冷却液状态	select	持续供给	持续供给,异常	f	f	t	11
3344	5	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
3346	5	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
3347	5	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
3348	5	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
3349	5	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
3350	5	环境与设备	1	detection_location	检测地点	text			f	t	f	6
3351	5	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	7
3352	5	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	8
3353	5	环境与设备	1	software	软件名称/版本	text			f	f	f	9
3354	5	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	10
3355	5	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	11
3356	5	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	12
3357	5	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	13
3358	5	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	14
3359	5	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	15
3360	5	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	16
3361	5	试验参数	2	start_temperature	起始温度/℃	number	25.0		f	f	f	1
3362	5	试验参数	2	end_temperature	终止温度/℃	number	550.0		f	f	f	2
3363	5	试验参数	2	heating_rate	升温速率/℃·min⁻¹（允许5±1）	number	5.0		f	f	f	3
3364	5	试验参数	2	sample_processing_state	制样/处理状态	select	原始状态	原始状态,热处理后,其他	f	f	t	4
3365	5	试验参数	2	pv_range	PV值/稳定范围	text	50～60		f	f	f	5
3366	5	试验参数	2	initial_pv	试验前PV实测值	number			f	f	t	6
3367	5	试验参数	2	sample_install	试样安装状态	select		牢固,异常	f	f	f	7
3368	5	试验参数	2	curve_path	热膨胀曲线文件路径	text			f	f	f	8
3369	5	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
3370	5	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
3371	5	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3372	5	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
3373	5	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3374	5	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
3375	5	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
3376	5	母版补充现场观察	3	specimen_processing_state	试样加工及端面状态	text	尺寸及端面状态满足方法要求		f	f	t	9
3377	5	母版补充现场观察	3	baseline_stability_actual	启动前基线/PV稳定性	select	稳定	稳定,不稳定	f	f	t	10
3378	5	母版补充现场观察	3	program_execution_note	升温程序实际执行确认	text	按设定程序完整执行		f	f	t	11
3379	6	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
3380	6	环境与设备	1	test_date	检测日期	date			f	f	f	1
3381	6	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
3382	6	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
3383	6	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
3384	6	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
3385	6	环境与设备	1	detection_location	检测地点	text			f	t	f	6
3386	6	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
3387	6	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
3388	6	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
3389	6	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
3390	6	环境与设备	1	software	软件名称/版本	text			f	f	f	11
3391	6	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
3392	6	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
3393	6	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
3394	6	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
3395	6	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
3396	6	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
3397	6	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3398	6	温度、时间和观察条件	2	container_no	金属带孔容器编号	text			f	f	t	1
3399	6	温度、时间和观察条件	2	oven_temperature	烘箱温度/℃	number	100.0		f	f	f	2
3400	6	温度、时间和观察条件	2	first_heating_time	首次加热时间/min	number	20.0		f	f	f	3
3401	6	温度、时间和观察条件	2	first_heating_start	首次加热开始时间	text			f	f	f	4
3402	6	温度、时间和观察条件	2	first_heating_end	首次加热结束时间	text			f	f	f	5
3403	6	温度、时间和观察条件	2	transfer_time	转移时间/s	number	3.0		f	f	f	6
3404	6	温度、时间和观察条件	2	ice_water_temperature	冰水温度/℃	number	1.0		f	f	f	7
3405	6	温度、时间和观察条件	2	immersion_time	冰水浸泡时间/min	number	5.0		f	f	f	8
3406	6	温度、时间和观察条件	2	ice_immersion_start	冰水浸泡开始时间	text			f	f	f	9
3407	6	温度、时间和观察条件	2	ice_immersion_end	冰水浸泡结束时间	text			f	f	f	10
3408	6	温度、时间和观察条件	2	second_heating_time	再次加热时间/min	number	15.0		f	f	f	11
3409	6	温度、时间和观察条件	2	second_heating_start	再次加热开始时间	text			f	f	t	12
3410	6	温度、时间和观察条件	2	second_heating_end	再次加热结束时间	text			f	f	t	13
3411	6	温度、时间和观察条件	2	cooling_temperature	观察前冷却温度/℃	number	23.0		f	f	f	14
3412	6	温度、时间和观察条件	2	illumination	观察照度/lx	number	1000.0		f	f	f	15
3413	6	温度、时间和观察条件	2	magnification	放大倍数	number	10.0		f	f	f	16
3414	6	温度、时间和观察条件	2	cooling_start	自然冷却开始时间	text			f	f	f	17
3415	6	温度、时间和观察条件	2	cooling_end	自然冷却完成时间	text			f	f	f	18
3416	6	温度、时间和观察条件	2	surface_temperature	观察前样品表面温度/℃	number			f	f	t	19
3417	6	温度、时间和观察条件	2	timer_no	计时器编号	text			f	f	f	20
3418	6	温度、时间和观察条件	2	thermometer_no	温度计编号	text			f	f	f	21
3419	6	温度、时间和观察条件	2	monitor_1_time	试验前·测量时间	text			f	f	t	22
3420	6	温度、时间和观察条件	2	monitor_1_temperature	试验前·冰水温度/℃	number	1.0		f	f	t	23
3421	6	温度、时间和观察条件	2	monitor_1_stable	试验前·稳定读数≥30s	select	是	是,否	f	f	f	24
3422	6	温度、时间和观察条件	2	monitor_1_status	试验前·处理状态	select	符合	符合,偏离	f	f	f	25
3423	6	温度、时间和观察条件	2	monitor_1_note	试验前·处理措施/备注	text			f	f	t	26
3424	6	温度、时间和观察条件	2	monitor_2_time	样品入水前·测量时间	text			f	f	t	27
3425	6	温度、时间和观察条件	2	monitor_2_temperature	样品入水前·冰水温度/℃	number	1.0		f	f	t	28
3426	6	温度、时间和观察条件	2	monitor_2_stable	样品入水前·稳定读数≥30s	select	是	是,否	f	f	f	29
3427	6	温度、时间和观察条件	2	monitor_2_status	样品入水前·处理状态	select	符合	符合,偏离	f	f	f	30
3428	6	温度、时间和观察条件	2	monitor_2_note	样品入水前·处理措施/备注	text			f	f	t	31
3429	6	温度、时间和观察条件	2	monitor_3_time	样品入水15s·测量时间	text			f	f	t	32
3430	6	温度、时间和观察条件	2	monitor_3_temperature	样品入水15s·冰水温度/℃	number	1.0		f	f	t	33
3431	6	温度、时间和观察条件	2	monitor_3_stable	样品入水15s·稳定读数≥30s	select	是	是,否	f	f	f	34
3432	6	温度、时间和观察条件	2	monitor_3_status	样品入水15s·处理状态	select	符合	符合,偏离	f	f	f	35
3433	6	温度、时间和观察条件	2	monitor_3_note	样品入水15s·处理措施/备注	text			f	f	t	36
3434	6	温度、时间和观察条件	2	monitor_4_time	样品入水30s·测量时间	text			f	f	t	37
3435	6	温度、时间和观察条件	2	monitor_4_temperature	样品入水30s·冰水温度/℃	number	1.0		f	f	t	38
3436	6	温度、时间和观察条件	2	monitor_4_stable	样品入水30s·稳定读数≥30s	select	是	是,否	f	f	f	39
3437	6	温度、时间和观察条件	2	monitor_4_status	样品入水30s·处理状态	select	符合	符合,偏离	f	f	f	40
3438	6	温度、时间和观察条件	2	monitor_4_note	样品入水30s·处理措施/备注	text			f	f	t	41
3439	6	温度、时间和观察条件	2	monitor_5_time	样品入烘箱后·测量时间	text			f	f	t	42
3440	6	温度、时间和观察条件	2	monitor_5_temperature	样品入烘箱后·冰水温度/℃	number	1.0		f	f	t	43
3441	6	温度、时间和观察条件	2	monitor_5_stable	样品入烘箱后·稳定读数≥30s	select	是	是,否	f	f	f	44
3442	6	温度、时间和观察条件	2	monitor_5_status	样品入烘箱后·处理状态	select	符合	符合,偏离	f	f	f	45
3443	6	温度、时间和观察条件	2	monitor_5_note	样品入烘箱后·处理措施/备注	text			f	f	t	46
3444	6	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
3445	6	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
3446	6	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3447	6	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
3448	6	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3449	6	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
3742	12	检验参数	2	retention	固位力	select	合格	合格,不足,过紧	f	f	f	5
3027	26	环境与设备	1	test_date	检测日期	date		[]	f	f	f	0
3028	26	光照、水浴和观察条件	2	source_type	发光源	select	氙灯	["氙灯","等同光源"]	f	f	f	0
3029	26	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
3030	26	光照、水浴和观察条件	2	lamp_no	氙灯编号/批号	text		[]	f	f	f	0
3031	26	环境与设备	1	temperature_before	检测前温度/℃	number	23	[]	f	f	f	0
3032	26	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
3033	26	环境与设备	1	temperature_after	检测后温度/℃	number	23	[]	f	f	f	0
3034	26	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	["符合","不符合"]	f	f	f	0
3035	26	光照、水浴和观察条件	2	lamp_hours	氙灯累计使用时间/h	number		[]	f	f	f	0
3036	26	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
3037	26	环境与设备	1	humidity_before	检测前湿度/%RH	number	50	[]	f	f	f	0
3038	26	光照、水浴和观察条件	2	filter_no	滤光片编号/批号	text		[]	f	f	f	0
3039	26	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	["已核对且在有效期内","存在异常"]	f	f	f	0
3040	26	环境与设备	1	humidity_after	检测后湿度/%RH	number	50	[]	f	f	f	0
3041	26	光照、水浴和观察条件	2	filter_hours	滤光片累计使用时间/h	number		[]	f	f	f	0
3042	26	环境与设备	1	detection_location	检测地点	text		[]	f	t	f	0
3043	26	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text		[]	f	t	f	0
3044	26	光照、水浴和观察条件	2	water_temperature	水浴温度/℃	number	37	[]	f	f	f	0
3045	26	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认	[]	f	f	f	0
3046	26	光照、水浴和观察条件	2	sample_illuminance	试样表面照度/lx	number	150000	[]	f	f	f	0
3047	26	环境与设备	1	start_time	实验开始时间	datetime		[]	f	f	f	0
3048	26	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	["一致","存在偏离"]	f	f	f	0
3049	26	环境与设备	1	end_time	实验结束时间	datetime		[]	f	f	f	0
3050	26	光照、水浴和观察条件	2	water_distance	试样与水面距离/mm	number	10	[]	f	f	f	0
3051	26	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	["无明显干扰","有干扰"]	f	f	f	0
3052	26	母版补充现场观察	3	control_sample_confirmation	对照试样及编号确认	select	符合	["符合","不符合"]	f	f	f	0
3053	26	光照、水浴和观察条件	2	exposure_time	照射时间/h	number	24	[]	f	f	f	0
3054	26	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
3055	26	母版补充现场观察	3	observer_identity_note	三名观察者身份及资格记录	text	已核对三名观察者身份及颜色视觉资格	[]	f	f	f	0
3056	26	光照、水浴和观察条件	2	water_medium	水浴介质	select		["蒸馏水","去离子水"]	f	f	f	0
3057	26	母版补充现场观察	3	d65_environment_ready	D65灯箱、背景及观察环境	select	符合	["符合","不符合"]	f	f	f	0
3058	26	环境与设备	1	software	软件名称/版本	text		[]	f	f	f	0
3059	26	光照、水浴和观察条件	2	d65_illuminance	D65灯箱观察照度/lx	number	1500	[]	f	f	f	0
3060	26	母版补充现场观察	3	lamp_filter_service_note	光源/滤光片编号及使用时间核对	text	已核对且在受控使用范围内	[]	f	f	f	0
3061	26	光照、水浴和观察条件	2	background	观察背景板	select		["N5中性灰","白背景+灰背景","其他"]	f	f	f	0
3062	26	环境与设备	1	data_path	仪器原始数据保存路径	text		[]	f	f	f	0
3063	26	母版补充现场观察	3	sample_position_note	试样位置、遮盖及水位说明	text	位置、遮盖和水位符合方法要求	[]	f	f	f	0
3064	26	环境与设备	1	equipment_name	主要设备名称	text		[]	f	t	f	0
3065	26	光照、水浴和观察条件	2	observation_distance	观察距离/mm	number	250	[]	f	f	f	0
3066	26	环境与设备	1	equipment_model	设备型号/规格	text		[]	f	t	f	0
3067	26	光照、水浴和观察条件	2	single_observation_time	单次观察时间/s	number	2	[]	f	f	f	0
3068	26	光照、水浴和观察条件	2	observer_1	观察者1姓名/颜色视觉记录	text		[]	f	f	f	0
3069	26	环境与设备	1	equipment_no	设备管理编号	text		[]	f	t	f	0
3070	26	光照、水浴和观察条件	2	observer_2	观察者2姓名/颜色视觉记录	text		[]	f	f	f	0
3071	26	环境与设备	1	calibration_certificate	校准/检定证书编号	text		[]	f	t	f	0
3072	26	光照、水浴和观察条件	2	observer_3	观察者3姓名/颜色视觉记录	text		[]	f	f	f	0
3073	26	环境与设备	1	calibration_due	台账校准时间	text		[]	f	t	f	0
3074	26	环境与设备	1	equipment_status	使用前设备状态	select		["正常","异常"]	f	f	f	0
3075	26	光照、水浴和观察条件	2	observer_qualification	三名观察者颜色视觉资格	select	均已确认合格	["均已确认合格","存在未确认/不合格"]	f	f	f	0
3076	26	光照、水浴和观察条件	2	exposure_start	照射开始时间	datetime		[]	f	f	f	0
3077	26	光照、水浴和观察条件	2	exposure_end	照射结束时间	datetime		[]	f	f	f	0
3078	26	光照、水浴和观察条件	2	water_temperature_end	结束时水浴温度/℃	number		[]	f	f	f	0
3079	26	光照、水浴和观察条件	2	sample_illuminance_end	结束时试样表面照度/lx	number		[]	f	f	f	0
3080	26	光照、水浴和观察条件	2	water_distance_end	结束时水面距离/mm	number		[]	f	f	f	0
3081	26	光照、水浴和观察条件	2	lamp_box_ready	D65灯箱预热/稳定	select	已完成	["已完成","未完成"]	f	f	f	0
3082	26	光照、水浴和观察条件	2	observation_date	目视观察日期	date		[]	f	f	f	0
3083	26	光照、水浴和观察条件	2	color_monitor_1_datetime	开始·日期/时间	datetime		[]	f	f	f	0
3084	26	光照、水浴和观察条件	2	color_monitor_1_runtime	开始·累计时间/h	number	0	[]	f	f	f	0
3085	26	光照、水浴和观察条件	2	color_monitor_1_water_temperature	开始·水浴温度/℃	number	37	[]	f	f	f	0
3086	26	光照、水浴和观察条件	2	color_monitor_1_illuminance	开始·试样表面照度/lx	number	150000	[]	f	f	f	0
3087	26	光照、水浴和观察条件	2	color_monitor_1_distance	开始·水面距离/mm	number	10	[]	f	f	f	0
3088	26	光照、水浴和观察条件	2	color_monitor_1_device_status	开始·设备状态	select	正常	["正常","异常"]	f	f	f	0
3089	26	光照、水浴和观察条件	2	color_monitor_1_sample_status	开始·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3090	26	光照、水浴和观察条件	2	color_monitor_1_note	开始·备注	text		[]	f	f	f	0
3091	26	光照、水浴和观察条件	2	color_monitor_2_datetime	过程1·日期/时间	datetime		[]	f	f	f	0
3092	26	光照、水浴和观察条件	2	color_monitor_2_runtime	过程1·累计时间/h	number	4	[]	f	f	f	0
3093	26	光照、水浴和观察条件	2	color_monitor_2_water_temperature	过程1·水浴温度/℃	number	37	[]	f	f	f	0
3094	26	光照、水浴和观察条件	2	color_monitor_2_illuminance	过程1·试样表面照度/lx	number	150000	[]	f	f	f	0
3095	26	光照、水浴和观察条件	2	color_monitor_2_distance	过程1·水面距离/mm	number	10	[]	f	f	f	0
3096	26	光照、水浴和观察条件	2	color_monitor_2_device_status	过程1·设备状态	select	正常	["正常","异常"]	f	f	f	0
3097	26	光照、水浴和观察条件	2	color_monitor_2_sample_status	过程1·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3098	26	光照、水浴和观察条件	2	color_monitor_2_note	过程1·备注	text		[]	f	f	f	0
3099	26	光照、水浴和观察条件	2	color_monitor_3_datetime	过程2·日期/时间	datetime		[]	f	f	f	0
3100	26	光照、水浴和观察条件	2	color_monitor_3_runtime	过程2·累计时间/h	number	8	[]	f	f	f	0
3101	26	光照、水浴和观察条件	2	color_monitor_3_water_temperature	过程2·水浴温度/℃	number	37	[]	f	f	f	0
3102	26	光照、水浴和观察条件	2	color_monitor_3_illuminance	过程2·试样表面照度/lx	number	150000	[]	f	f	f	0
3103	26	光照、水浴和观察条件	2	color_monitor_3_distance	过程2·水面距离/mm	number	10	[]	f	f	f	0
3104	26	光照、水浴和观察条件	2	color_monitor_3_device_status	过程2·设备状态	select	正常	["正常","异常"]	f	f	f	0
3105	26	光照、水浴和观察条件	2	color_monitor_3_sample_status	过程2·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3106	26	光照、水浴和观察条件	2	color_monitor_3_note	过程2·备注	text		[]	f	f	f	0
3107	26	光照、水浴和观察条件	2	color_monitor_4_datetime	过程3·日期/时间	datetime		[]	f	f	f	0
3108	26	光照、水浴和观察条件	2	color_monitor_4_runtime	过程3·累计时间/h	number	12	[]	f	f	f	0
3109	26	光照、水浴和观察条件	2	color_monitor_4_water_temperature	过程3·水浴温度/℃	number	37	[]	f	f	f	0
3110	26	光照、水浴和观察条件	2	color_monitor_4_illuminance	过程3·试样表面照度/lx	number	150000	[]	f	f	f	0
3111	26	光照、水浴和观察条件	2	color_monitor_4_distance	过程3·水面距离/mm	number	10	[]	f	f	f	0
3112	26	光照、水浴和观察条件	2	color_monitor_4_device_status	过程3·设备状态	select	正常	["正常","异常"]	f	f	f	0
3113	26	光照、水浴和观察条件	2	color_monitor_4_sample_status	过程3·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3114	26	光照、水浴和观察条件	2	color_monitor_4_note	过程3·备注	text		[]	f	f	f	0
3115	26	光照、水浴和观察条件	2	color_monitor_5_datetime	过程4·日期/时间	datetime		[]	f	f	f	0
3116	26	光照、水浴和观察条件	2	color_monitor_5_runtime	过程4·累计时间/h	number	20	[]	f	f	f	0
3117	26	光照、水浴和观察条件	2	color_monitor_5_water_temperature	过程4·水浴温度/℃	number	37	[]	f	f	f	0
3118	26	光照、水浴和观察条件	2	color_monitor_5_illuminance	过程4·试样表面照度/lx	number	150000	[]	f	f	f	0
3119	26	光照、水浴和观察条件	2	color_monitor_5_distance	过程4·水面距离/mm	number	10	[]	f	f	f	0
3120	26	光照、水浴和观察条件	2	color_monitor_5_device_status	过程4·设备状态	select	正常	["正常","异常"]	f	f	f	0
3121	26	光照、水浴和观察条件	2	color_monitor_5_sample_status	过程4·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3122	26	光照、水浴和观察条件	2	color_monitor_5_note	过程4·备注	text		[]	f	f	f	0
3123	26	光照、水浴和观察条件	2	color_monitor_6_datetime	结束·日期/时间	datetime		[]	f	f	f	0
3124	26	光照、水浴和观察条件	2	color_monitor_6_runtime	结束·累计时间/h	number	24	[]	f	f	f	0
3125	26	光照、水浴和观察条件	2	color_monitor_6_water_temperature	结束·水浴温度/℃	number	37	[]	f	f	f	0
3126	26	光照、水浴和观察条件	2	color_monitor_6_illuminance	结束·试样表面照度/lx	number	150000	[]	f	f	f	0
3127	26	光照、水浴和观察条件	2	color_monitor_6_distance	结束·水面距离/mm	number	10	[]	f	f	f	0
3128	26	光照、水浴和观察条件	2	color_monitor_6_device_status	结束·设备状态	select	正常	["正常","异常"]	f	f	f	0
3129	26	光照、水浴和观察条件	2	color_monitor_6_sample_status	结束·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3130	26	光照、水浴和观察条件	2	color_monitor_6_note	结束·备注	text		[]	f	f	f	0
3450	6	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
3451	6	母版补充现场观察	3	initial_appearance_actual	试验前逐件外观状态	text	逐件检查未见裂纹、崩瓷或破损		f	f	t	9
3452	6	母版补充现场观察	3	transfer_compliance	热冷转移时间与浸没状态	select	符合	符合,不符合	f	f	t	10
3453	6	母版补充现场观察	3	inspection_condition	观察照度、放大条件及冷却状态	select	符合	符合,不符合	f	f	t	11
3454	7	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
3455	7	试样、夹具和软件参数	2	roller_radius	压头/支点R/mm	number	2.0		f	f	f	12
3456	7	环境与设备	1	test_date	检测日期	date			f	f	f	1
3457	7	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
3458	7	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
3459	7	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
3460	7	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
3461	7	环境与设备	1	detection_location	检测地点	text			f	t	f	6
3462	7	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
3463	7	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
3464	7	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
3465	7	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
3466	7	环境与设备	1	software	软件名称/版本	text			f	f	f	11
3467	7	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
3468	7	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
3469	7	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
3470	7	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
3471	7	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
3472	7	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
3473	7	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3474	7	试样、夹具和软件参数	2	printing_process	打印工艺/设备	text			f	f	f	1
3475	7	试样、夹具和软件参数	2	heat_treatment_record	热处理记录编号	text			f	f	f	2
3476	7	试样、夹具和软件参数	2	printing_direction	打印方向	select		长轴平行z轴,长轴垂直z轴（x/y轴）	f	f	f	3
3477	7	试样、夹具和软件参数	2	force_sensor	2000N力传感器编号	text			f	f	f	4
3478	7	试样、夹具和软件参数	2	sensor_calibration_value	力传感器校准值/N	number			f	f	t	5
3479	7	试样、夹具和软件参数	2	sensor_coefficient	力传感器校准系数	number			f	f	t	6
3480	7	试样、夹具和软件参数	2	deflectometer	挠度计/变形测量装置编号	text			f	f	f	7
3481	7	试样、夹具和软件参数	2	fixture_no	三点弯曲夹具编号	text			f	f	f	8
3482	7	试样、夹具和软件参数	2	support_span	支点距离/mm	number	20.0		f	f	f	9
3483	7	试样、夹具和软件参数	2	speed	位移速度/mm/min	number	1.0		f	f	f	10
3484	7	试样、夹具和软件参数	2	specified_strain	规定应变/%	number	0.2		f	f	f	11
3485	7	试样、夹具和软件参数	2	fixture_parallel	上压头/下支撑平行	select		是,否	f	f	f	13
3486	7	试样、夹具和软件参数	2	max_gap	平行块/塞尺最大间隙/mm	number			f	f	f	14
3487	7	试样、夹具和软件参数	2	deflectometer_contact	挠度计状态	select		轻微接触,预压,未接触	f	f	f	15
3488	7	试样、夹具和软件参数	2	zero_force	清零后力值/N	number			f	f	f	16
3489	7	试样、夹具和软件参数	2	start_permission	开始试验条件	select	可以开始试验	可以开始试验,需调整后再试验	f	f	f	17
3490	7	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
3491	7	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
3492	7	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3493	7	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
3494	7	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3495	7	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
3496	7	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
3497	7	母版补充现场观察	3	specimen_direction	试样/打印方向	text	已按委托及方法要求确认		f	f	t	9
3498	7	母版补充现场观察	3	fixture_centering	夹具平行、试样居中及紧固确认	select	符合	符合,不符合	f	f	t	10
3499	7	母版补充现场观察	3	zero_and_contact	力值调零及挠度计接触确认	select	符合	符合,不符合	f	f	t	11
3500	8	硬度和试样表面确认	2	sample_production_date	样品批号	text	\N		f	t	f	1
3501	8	环境与设备	1	test_date	检测日期	date			f	f	f	1
3502	8	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
3503	8	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
3504	8	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
3505	8	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
3506	8	环境与设备	1	detection_location	检测地点	text			f	t	f	6
3507	8	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
3508	8	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
3509	8	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
3510	8	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
3511	8	环境与设备	1	software	软件名称/版本	text			f	f	f	11
3512	8	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
3513	8	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
3514	8	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
3515	8	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
3516	8	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
3517	8	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
3518	8	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3519	8	硬度和试样表面确认	2	method	试验力级别	text	HV10		f	f	f	2
3520	8	硬度和试样表面确认	2	test_force	试验力/N	number	98.07		f	f	f	3
3521	8	硬度和试样表面确认	2	dwell_time	保荷时间/s	number	15.0		f	f	f	4
3522	8	硬度和试样表面确认	2	standard_block_no	标准硬度块编号	text	BPGL-B007		f	f	f	5
3523	8	硬度和试样表面确认	2	standard_block_nominal	标准硬度块标称值/HV	number	466.0		f	f	f	6
3524	8	硬度和试样表面确认	2	standard_block_due	标准硬度块有效期	date			f	f	f	7
3525	8	硬度和试样表面确认	2	standard_block_reading_1	标准硬度块实测值1/HV	number			f	f	t	8
3526	8	硬度和试样表面确认	2	standard_block_reading_2	标准硬度块实测值2/HV	number			f	f	t	9
3527	8	硬度和试样表面确认	2	standard_block_reading_3	标准硬度块实测值3/HV	number			f	f	t	10
3528	8	硬度和试样表面确认	2	standard_block_result	标准硬度块核查结果	select		合格,不合格	f	f	f	11
3529	8	硬度和试样表面确认	2	surface_condition	测试面状态	select		平整清洁,异常	f	f	f	12
3530	8	硬度和试样表面确认	2	perpendicularity	试样垂直性确认	select		符合,不符合	f	f	f	13
3531	8	硬度和试样表面确认	2	indent_measurement_method	压痕测量方式	text	切线测量		f	f	f	14
3532	8	硬度和试样表面确认	2	report_exported	硬度报告已导出	select	是	是,否	f	f	f	15
3533	8	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
3534	8	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
3535	8	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3536	8	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
3537	8	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3538	8	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	6
3539	8	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	7
3540	8	母版补充现场观察	3	surface_preparation_hv	测试面磨制/抛光及清洁状态	text	表面平整清洁且不影响压痕		f	f	t	8
3541	8	母版补充现场观察	3	software_version_actual	本次硬度测量软件版本	text	由设备配置核对		f	f	t	9
3542	8	母版补充现场观察	3	loading_unloading_confirmation	加载、保荷及卸载过程	select	正常	正常,异常	f	f	t	10
3543	9	影像测量参数	2	sample_production_date	样品批号	text	\N		t	t	f	1
3544	9	影像测量参数	2	production_date	生产日期	text	\N		t	t	f	2
3545	9	环境与设备	1	test_date	检测日期	date			f	f	f	1
3546	9	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
3547	9	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
3548	9	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
3549	9	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
3550	9	环境与设备	1	detection_location	检测地点	text			f	t	f	6
3551	9	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
3552	9	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
3553	9	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
3554	9	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
3555	9	环境与设备	1	software	软件名称/版本	text			f	f	f	11
3556	9	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
3557	9	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
3558	9	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
3559	9	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
3560	9	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
3561	9	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
3562	9	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3563	9	影像测量参数	2	magnification	测试放大倍数	text	33倍		f	f	f	3
3564	9	影像测量参数	2	calibration_nominal	标准量块标称值/mm	number			f	f	t	4
3565	9	影像测量参数	2	calibration_measured	标准量块实测值/mm	number			f	f	t	5
3566	9	影像测量参数	2	calibration_result	校准核查结果	select		合格,不合格	f	f	f	6
3567	9	影像测量参数	2	preheat_start	设备预热开始时间	text			f	f	f	7
3568	9	影像测量参数	2	preheat_end	设备预热结束时间	text			f	f	f	8
3569	9	影像测量参数	2	measurement_points	测量点位	text	固定端、中点、自由端		f	f	f	9
3570	9	影像测量参数	2	repeat_count	每个试样重复测量次数	number	1.0		f	f	f	10
3571	9	影像测量参数	2	design_thickness	设计厚度/mm	number			f	f	t	11
3572	9	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
3573	9	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
3574	9	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3743	12	检验参数	2	stability	稳定性	select	合格	合格,不合格	f	f	f	6
2168	18	环境与设备	1	test_date	检测日期	date			f	f	f	1
2169	18	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2170	18	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2171	18	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2172	18	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2173	18	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2174	18	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2175	18	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2176	18	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2177	18	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2178	18	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2179	18	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2180	18	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2181	18	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2182	18	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2183	18	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2184	18	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2185	18	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
2186	18	裂纹萌生试验参数	2	fixture_no	金瓷结合试验夹具编号	text	BPGL-B009		f	f	f	1
2187	18	裂纹萌生试验参数	2	support_span	支承跨距/mm	number	20.0		f	f	f	2
2188	18	裂纹萌生试验参数	2	roller_radius	压头/支点半径R/mm	number	1.0		f	f	f	3
2189	18	裂纹萌生试验参数	2	parallel_block_no	平行块编号	text	BGGL-B019		f	f	f	4
2190	18	裂纹萌生试验参数	2	parallel_block_parallelism	平行块平行度/mm	number			f	f	t	5
2191	18	裂纹萌生试验参数	2	loading_speed	加载速度/mm/min	number	1.5		f	f	f	6
2192	18	裂纹萌生试验参数	2	observation_method	裂纹萌生观察方式	select	目视	声响,目视	f	f	f	7
2193	18	裂纹萌生试验参数	2	parallel_check	夹具平行与居中确认	select		符合,不符合	f	f	f	8
2194	18	裂纹萌生试验参数	2	metal_name	试样名称	text			f	t	f	9
2195	18	裂纹萌生试验参数	2	metal_batch	批号	text			f	t	f	10
2196	18	裂纹萌生试验参数	2	em_source	杨氏模量来源	select	说明书	说明书,检测报告,注册资料,质保书,其他	f	f	f	11
2197	18	裂纹萌生试验参数	2	em_source_file	杨氏模量来源文件编号	text			f	f	f	12
2198	18	裂纹萌生试验参数	2	orientation	试样放置方向	select		金属面朝上、陶瓷面朝下,其他	f	f	f	13
2199	18	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2200	18	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2201	18	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2202	18	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2203	18	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
2204	18	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	6
2205	18	母版补充现场观察	3	centering_confirmation	试样居中及跨距确认	select	符合	符合,不符合	f	f	t	7
2206	18	母版补充现场观察	3	crack_observation_note	裂纹萌生/陶瓷剥离观察说明	text	按声响或目视结果判定		f	f	t	8
2207	19	环境与设备	1	test_date	检测日期	date			f	f	f	1
2208	19	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2209	19	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2210	19	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2211	19	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2212	19	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2213	19	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2214	19	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2215	19	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2216	19	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2217	19	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2218	19	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2219	19	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2220	19	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2221	19	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2222	19	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2223	19	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2224	19	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
2225	19	辐射安全与曝光参数	2	radiation_safety	辐射安全确认	select		允许曝光,禁止曝光	f	f	f	1
2226	19	辐射安全与曝光参数	2	xray_model	X射线机型号/编号	text			f	f	f	2
2227	19	辐射安全与曝光参数	2	panel_no	数据采集板编号	text			f	f	f	3
2228	19	辐射安全与曝光参数	2	iqi_no	孔形像质计编号	text			f	f	f	4
2229	19	辐射安全与曝光参数	2	density_meter_no	密度计/标准密度片编号	text			f	f	f	5
2230	19	辐射安全与曝光参数	2	density_nominal	标准密度片标称值	number			f	f	t	6
2231	19	辐射安全与曝光参数	2	density_measured_1	标准密度片实测值1	number			f	f	t	7
2232	19	辐射安全与曝光参数	2	density_measured_2	标准密度片实测值2	number			f	f	t	8
2233	19	辐射安全与曝光参数	2	density_measured_3	标准密度片实测值3	number			f	f	t	9
2234	19	辐射安全与曝光参数	2	tube_voltage	管电压/kV	number	75.0		f	f	f	10
2235	19	辐射安全与曝光参数	2	tube_current	管电流/mA	number	56.0		f	f	f	11
2236	19	辐射安全与曝光参数	2	exposure_time	曝光时间/ms	number	110.0		f	f	f	12
2237	19	辐射安全与曝光参数	2	mas	管电流时间积/mAs	number	6.3		f	f	f	13
2238	19	辐射安全与曝光参数	2	focus_mode	焦点模式	text	L		f	f	f	14
2239	19	辐射安全与曝光参数	2	orientation	样品摆放方向	text	咬合面朝下		f	f	f	15
2240	19	辐射安全与曝光参数	2	exposure_count	曝光次数	number	1.0		f	f	f	16
2241	19	辐射安全与曝光参数	2	parameter_adjustment	参数调整情况	select	无调整	无调整,有调整	f	f	f	17
2242	19	辐射安全与曝光参数	2	iqi_gray_01_1	像质计0.1 mm灰度·第1次	number			f	f	t	18
2243	19	辐射安全与曝光参数	2	iqi_gray_01_2	像质计0.1 mm灰度·第2次	number			f	f	t	19
2244	19	辐射安全与曝光参数	2	iqi_gray_01_3	像质计0.1 mm灰度·第3次	number			f	f	t	20
2245	19	辐射安全与曝光参数	2	iqi_gray_02_1	像质计0.2 mm灰度·第1次	number			f	f	t	21
2246	19	辐射安全与曝光参数	2	iqi_gray_02_2	像质计0.2 mm灰度·第2次	number			f	f	t	22
2247	19	辐射安全与曝光参数	2	iqi_gray_02_3	像质计0.2 mm灰度·第3次	number			f	f	t	23
2248	19	辐射安全与曝光参数	2	iqi_gray_03_1	像质计0.3 mm灰度·第1次	number			f	f	t	24
2249	19	辐射安全与曝光参数	2	iqi_gray_03_2	像质计0.3 mm灰度·第2次	number			f	f	t	25
2250	19	辐射安全与曝光参数	2	iqi_gray_03_3	像质计0.3 mm灰度·第3次	number			f	f	t	26
2251	19	辐射安全与曝光参数	2	iqi_gray_04_1	像质计0.4 mm灰度·第1次	number			f	f	t	27
2252	19	辐射安全与曝光参数	2	iqi_gray_04_2	像质计0.4 mm灰度·第2次	number			f	f	t	28
2253	19	辐射安全与曝光参数	2	iqi_gray_04_3	像质计0.4 mm灰度·第3次	number			f	f	t	29
2254	19	辐射安全与曝光参数	2	iqi_gray_05_1	像质计0.5 mm灰度·第1次	number			f	f	t	30
2255	19	辐射安全与曝光参数	2	iqi_gray_05_2	像质计0.5 mm灰度·第2次	number			f	f	t	31
2256	19	辐射安全与曝光参数	2	iqi_gray_05_3	像质计0.5 mm灰度·第3次	number			f	f	t	32
2257	19	辐射安全与曝光参数	2	iqi_gray_06_1	像质计0.6 mm灰度·第1次	number			f	f	t	33
2258	19	辐射安全与曝光参数	2	iqi_gray_06_2	像质计0.6 mm灰度·第2次	number			f	f	t	34
2259	19	辐射安全与曝光参数	2	iqi_gray_06_3	像质计0.6 mm灰度·第3次	number			f	f	t	35
2260	19	辐射安全与曝光参数	2	iqi_gray_07_1	像质计0.7 mm灰度·第1次	number			f	f	t	36
2261	19	辐射安全与曝光参数	2	iqi_gray_07_2	像质计0.7 mm灰度·第2次	number			f	f	t	37
2262	19	辐射安全与曝光参数	2	iqi_gray_07_3	像质计0.7 mm灰度·第3次	number			f	f	t	38
2263	19	辐射安全与曝光参数	2	iqi_gray_08_1	像质计0.8 mm灰度·第1次	number			f	f	t	39
2264	19	辐射安全与曝光参数	2	iqi_gray_08_2	像质计0.8 mm灰度·第2次	number			f	f	t	40
2265	19	辐射安全与曝光参数	2	iqi_gray_08_3	像质计0.8 mm灰度·第3次	number			f	f	t	41
2266	19	辐射安全与曝光参数	2	iqi_gray_09_1	像质计0.9 mm灰度·第1次	number			f	f	t	42
2267	19	辐射安全与曝光参数	2	iqi_gray_09_2	像质计0.9 mm灰度·第2次	number			f	f	t	43
2268	19	辐射安全与曝光参数	2	iqi_gray_09_3	像质计0.9 mm灰度·第3次	number			f	f	t	44
2269	19	辐射安全与曝光参数	2	iqi_gray_10_1	像质计1.0 mm灰度·第1次	number			f	f	t	45
2270	19	辐射安全与曝光参数	2	iqi_gray_10_2	像质计1.0 mm灰度·第2次	number			f	f	t	46
2271	19	辐射安全与曝光参数	2	iqi_gray_10_3	像质计1.0 mm灰度·第3次	number			f	f	t	47
2272	19	辐射安全与曝光参数	2	image_path	原始图像保存路径	text			f	f	f	48
2273	19	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2274	19	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2275	19	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2276	19	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2277	19	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3575	9	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2279	19	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
2280	19	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
2281	19	母版补充现场观察	3	sample_surface_xray	样品表面清洁、干燥状态	select	符合	符合,不符合	f	f	t	9
2282	19	母版补充现场观察	3	radiation_zone_clear	辐射区域无无关人员及物品	select	符合	符合,不符合	f	f	t	10
2283	19	母版补充现场观察	3	panel_iqi_position_confirmation	探测板、像质计与样品位置确认	select	符合	符合,不符合	f	f	t	11
2284	19	母版补充现场观察	3	operator_authorization	X射线操作授权确认	select	已授权	已授权,未授权	f	f	t	12
2285	19	母版补充现场观察	3	density_control_note	密度/灰度标准控制范围及核查说明	text	核查结果在受控范围内		f	f	t	13
2286	20	环境与设备	1	test_date	检测日期	date			f	f	f	1
2287	20	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2288	20	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2289	20	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2290	20	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2291	20	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2292	20	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2293	20	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2294	20	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2295	20	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2296	20	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2297	20	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2298	20	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2299	20	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2300	20	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2301	20	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2302	20	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2303	20	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
2304	20	测量和切割参数	2	image_device_no	二次元影像仪编号	text			f	f	f	1
2305	20	测量和切割参数	2	software_version	测量软件/版本	text			f	f	f	2
2306	20	测量和切割参数	2	cutting_device_no	切割设备编号	text			f	f	f	3
2307	20	测量和切割参数	2	fixture_no	专用试样夹具编号	text			f	f	f	4
2308	20	测量和切割参数	2	cutting_disc	切割片规格/批号	text			f	f	f	5
2309	20	测量和切割参数	2	measurement_function	测量功能	text	Point to Line		f	f	f	6
2310	20	测量和切割参数	2	baseline_before	切割前基准线确认	select		符合,不符合	f	f	f	7
2311	20	测量和切割参数	2	coolant	切割冷却液状态	select		持续供给,异常	f	f	f	8
2312	20	测量和切割参数	2	cut_position	切割位置/方向	text			f	f	f	9
2313	20	测量和切割参数	2	spindle_speed	主轴转速实设/显示	text			f	f	f	10
2314	20	测量和切割参数	2	cutting_stroke	切割行程	number	50.0		f	f	f	11
2315	20	测量和切割参数	2	feed_speed	进给速度	number	0.1		f	f	f	12
2316	20	测量和切割参数	2	baseline_after	切割后基准线确认	select		符合,不符合	f	f	f	13
2317	20	测量和切割参数	2	image_before_path	切割前原始图像路径	text			f	f	f	14
2318	20	测量和切割参数	2	image_after_path	切割后原始图像路径	text			f	f	f	15
2319	20	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2320	20	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2321	20	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2322	20	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2323	20	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3744	12	检验参数	2	base_thickness	基托厚度/mm	number			f	f	f	7
2325	20	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
2326	20	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
2327	20	母版补充现场观察	3	baseline_actual	切割前基准线实际确认	select	清晰且符合	清晰且符合,不符合	f	f	t	9
2328	20	母版补充现场观察	3	cutting_position_note	实际切割位置及方向说明	text	按受控方法规定位置和方向切割		f	f	t	10
2329	20	母版补充现场观察	3	coolant_actual	切割过程冷却液状态	select	持续供给	持续供给,异常	f	f	t	11
2330	21	环境与设备	1	test_date	检测日期	date			f	f	f	1
2331	21	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2332	21	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2333	21	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2334	21	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2335	21	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2336	21	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	7
2337	21	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	8
2338	21	环境与设备	1	software	软件名称/版本	text			f	f	f	9
2339	21	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	10
2340	21	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	11
2341	21	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	12
2342	21	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	13
2343	21	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	14
2344	21	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	15
2345	21	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	16
2346	21	试验参数	2	start_temperature	起始温度/℃	number	25.0		f	f	f	1
2347	21	试验参数	2	end_temperature	终止温度/℃	number	550.0		f	f	f	2
2348	21	试验参数	2	heating_rate	升温速率/℃·min⁻¹（允许5±1）	number	5.0		f	f	f	3
2349	21	试验参数	2	sample_processing_state	制样/处理状态	select	原始状态	原始状态,热处理后,其他	f	f	t	4
2350	21	试验参数	2	pv_range	PV值/稳定范围	text	50～60		f	f	f	5
2351	21	试验参数	2	initial_pv	试验前PV实测值	number			f	f	t	6
2352	21	试验参数	2	sample_install	试样安装状态	select		牢固,异常	f	f	f	7
2353	21	试验参数	2	curve_path	热膨胀曲线文件路径	text			f	f	f	8
2354	21	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2355	21	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2356	21	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2357	21	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2358	21	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3745	12	检验参数	2	clasp_thickness	卡环厚度/mm	number			f	f	f	8
2360	21	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
2361	21	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
2362	21	母版补充现场观察	3	specimen_processing_state	试样加工及端面状态	text	尺寸及端面状态满足方法要求		f	f	t	9
2363	21	母版补充现场观察	3	baseline_stability_actual	启动前基线/PV稳定性	select	稳定	稳定,不稳定	f	f	t	10
2364	21	母版补充现场观察	3	program_execution_note	升温程序实际执行确认	text	按设定程序完整执行		f	f	t	11
2365	22	环境与设备	1	test_date	检测日期	date			f	f	f	1
2366	22	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2367	22	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2368	22	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2369	22	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2370	22	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2371	22	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2372	22	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2373	22	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2374	22	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2375	22	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2376	22	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2377	22	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2378	22	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2379	22	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2380	22	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2381	22	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2382	22	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
2383	22	温度、时间和观察条件	2	container_no	金属带孔容器编号	text			f	f	t	1
2384	22	温度、时间和观察条件	2	oven_temperature	烘箱温度/℃	number	100.0		f	f	f	2
2385	22	温度、时间和观察条件	2	first_heating_time	首次加热时间/min	number	20.0		f	f	f	3
2386	22	温度、时间和观察条件	2	first_heating_start	首次加热开始时间	text			f	f	f	4
2387	22	温度、时间和观察条件	2	first_heating_end	首次加热结束时间	text			f	f	f	5
2388	22	温度、时间和观察条件	2	transfer_time	转移时间/s	number	3.0		f	f	f	6
2389	22	温度、时间和观察条件	2	ice_water_temperature	冰水温度/℃	number	1.0		f	f	f	7
2390	22	温度、时间和观察条件	2	immersion_time	冰水浸泡时间/min	number	5.0		f	f	f	8
2391	22	温度、时间和观察条件	2	ice_immersion_start	冰水浸泡开始时间	text			f	f	f	9
2392	22	温度、时间和观察条件	2	ice_immersion_end	冰水浸泡结束时间	text			f	f	f	10
2393	22	温度、时间和观察条件	2	second_heating_time	再次加热时间/min	number	15.0		f	f	f	11
2394	22	温度、时间和观察条件	2	second_heating_start	再次加热开始时间	text			f	f	t	12
2395	22	温度、时间和观察条件	2	second_heating_end	再次加热结束时间	text			f	f	t	13
2396	22	温度、时间和观察条件	2	cooling_temperature	观察前冷却温度/℃	number	23.0		f	f	f	14
2397	22	温度、时间和观察条件	2	illumination	观察照度/lx	number	1000.0		f	f	f	15
2398	22	温度、时间和观察条件	2	magnification	放大倍数	number	10.0		f	f	f	16
2399	22	温度、时间和观察条件	2	cooling_start	自然冷却开始时间	text			f	f	f	17
2400	22	温度、时间和观察条件	2	cooling_end	自然冷却完成时间	text			f	f	f	18
2401	22	温度、时间和观察条件	2	surface_temperature	观察前样品表面温度/℃	number			f	f	t	19
2402	22	温度、时间和观察条件	2	timer_no	计时器编号	text			f	f	f	20
2403	22	温度、时间和观察条件	2	thermometer_no	温度计编号	text			f	f	f	21
2404	22	温度、时间和观察条件	2	monitor_1_time	试验前·测量时间	text			f	f	t	22
2405	22	温度、时间和观察条件	2	monitor_1_temperature	试验前·冰水温度/℃	number	1.0		f	f	t	23
2406	22	温度、时间和观察条件	2	monitor_1_stable	试验前·稳定读数≥30s	select	是	是,否	f	f	f	24
2407	22	温度、时间和观察条件	2	monitor_1_status	试验前·处理状态	select	符合	符合,偏离	f	f	f	25
2408	22	温度、时间和观察条件	2	monitor_1_note	试验前·处理措施/备注	text			f	f	t	26
2409	22	温度、时间和观察条件	2	monitor_2_time	样品入水前·测量时间	text			f	f	t	27
2410	22	温度、时间和观察条件	2	monitor_2_temperature	样品入水前·冰水温度/℃	number	1.0		f	f	t	28
2411	22	温度、时间和观察条件	2	monitor_2_stable	样品入水前·稳定读数≥30s	select	是	是,否	f	f	f	29
2469	23	试样、夹具和软件参数	2	roller_radius	压头/支点R/mm	number	2.0		f	f	f	12
2412	22	温度、时间和观察条件	2	monitor_2_status	样品入水前·处理状态	select	符合	符合,偏离	f	f	f	30
2413	22	温度、时间和观察条件	2	monitor_2_note	样品入水前·处理措施/备注	text			f	f	t	31
2414	22	温度、时间和观察条件	2	monitor_3_time	样品入水15s·测量时间	text			f	f	t	32
2415	22	温度、时间和观察条件	2	monitor_3_temperature	样品入水15s·冰水温度/℃	number	1.0		f	f	t	33
2416	22	温度、时间和观察条件	2	monitor_3_stable	样品入水15s·稳定读数≥30s	select	是	是,否	f	f	f	34
2417	22	温度、时间和观察条件	2	monitor_3_status	样品入水15s·处理状态	select	符合	符合,偏离	f	f	f	35
2418	22	温度、时间和观察条件	2	monitor_3_note	样品入水15s·处理措施/备注	text			f	f	t	36
2419	22	温度、时间和观察条件	2	monitor_4_time	样品入水30s·测量时间	text			f	f	t	37
2420	22	温度、时间和观察条件	2	monitor_4_temperature	样品入水30s·冰水温度/℃	number	1.0		f	f	t	38
2421	22	温度、时间和观察条件	2	monitor_4_stable	样品入水30s·稳定读数≥30s	select	是	是,否	f	f	f	39
2422	22	温度、时间和观察条件	2	monitor_4_status	样品入水30s·处理状态	select	符合	符合,偏离	f	f	f	40
2423	22	温度、时间和观察条件	2	monitor_4_note	样品入水30s·处理措施/备注	text			f	f	t	41
2424	22	温度、时间和观察条件	2	monitor_5_time	样品入烘箱后·测量时间	text			f	f	t	42
2425	22	温度、时间和观察条件	2	monitor_5_temperature	样品入烘箱后·冰水温度/℃	number	1.0		f	f	t	43
2426	22	温度、时间和观察条件	2	monitor_5_stable	样品入烘箱后·稳定读数≥30s	select	是	是,否	f	f	f	44
2427	22	温度、时间和观察条件	2	monitor_5_status	样品入烘箱后·处理状态	select	符合	符合,偏离	f	f	f	45
2428	22	温度、时间和观察条件	2	monitor_5_note	样品入烘箱后·处理措施/备注	text			f	f	t	46
2429	22	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2430	22	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2431	22	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2432	22	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2433	22	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3746	12	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2435	22	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
2436	22	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
2437	22	母版补充现场观察	3	initial_appearance_actual	试验前逐件外观状态	text	逐件检查未见裂纹、崩瓷或破损		f	f	t	9
2438	22	母版补充现场观察	3	transfer_compliance	热冷转移时间与浸没状态	select	符合	符合,不符合	f	f	t	10
2439	22	母版补充现场观察	3	inspection_condition	观察照度、放大条件及冷却状态	select	符合	符合,不符合	f	f	t	11
2440	23	环境与设备	1	test_date	检测日期	date			f	f	f	1
2441	23	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2442	23	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2443	23	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2444	23	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2445	23	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2446	23	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2447	23	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2448	23	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2449	23	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2450	23	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2451	23	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2452	23	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2453	23	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2454	23	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2455	23	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2456	23	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2457	23	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
2458	23	试样、夹具和软件参数	2	printing_process	打印工艺/设备	text			f	f	f	1
2459	23	试样、夹具和软件参数	2	heat_treatment_record	热处理记录编号	text			f	f	f	2
2460	23	试样、夹具和软件参数	2	printing_direction	打印方向	select		长轴平行z轴,长轴垂直z轴（x/y轴）	f	f	f	3
2461	23	试样、夹具和软件参数	2	force_sensor	2000N力传感器编号	text			f	f	f	4
2462	23	试样、夹具和软件参数	2	sensor_calibration_value	力传感器校准值/N	number			f	f	t	5
2463	23	试样、夹具和软件参数	2	sensor_coefficient	力传感器校准系数	number			f	f	t	6
2464	23	试样、夹具和软件参数	2	deflectometer	挠度计/变形测量装置编号	text			f	f	f	7
2465	23	试样、夹具和软件参数	2	fixture_no	三点弯曲夹具编号	text			f	f	f	8
2466	23	试样、夹具和软件参数	2	support_span	支点距离/mm	number	20.0		f	f	f	9
2467	23	试样、夹具和软件参数	2	speed	位移速度/mm/min	number	1.0		f	f	f	10
2468	23	试样、夹具和软件参数	2	specified_strain	规定应变/%	number	0.2		f	f	f	11
2470	23	试样、夹具和软件参数	2	fixture_parallel	上压头/下支撑平行	select		是,否	f	f	f	13
2471	23	试样、夹具和软件参数	2	max_gap	平行块/塞尺最大间隙/mm	number			f	f	f	14
2472	23	试样、夹具和软件参数	2	deflectometer_contact	挠度计状态	select		轻微接触,预压,未接触	f	f	f	15
2473	23	试样、夹具和软件参数	2	zero_force	清零后力值/N	number			f	f	f	16
2474	23	试样、夹具和软件参数	2	start_permission	开始试验条件	select	可以开始试验	可以开始试验,需调整后再试验	f	f	f	17
2475	23	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2476	23	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2477	23	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2478	23	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2479	23	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3576	9	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
2481	23	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
2482	23	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
2483	23	母版补充现场观察	3	specimen_direction	试样/打印方向	text	已按委托及方法要求确认		f	f	t	9
2484	23	母版补充现场观察	3	fixture_centering	夹具平行、试样居中及紧固确认	select	符合	符合,不符合	f	f	t	10
2485	23	母版补充现场观察	3	zero_and_contact	力值调零及挠度计接触确认	select	符合	符合,不符合	f	f	t	11
2486	24	环境与设备	1	test_date	检测日期	date			f	f	f	1
2487	24	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2488	24	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2489	24	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2490	24	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2491	24	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2492	24	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2493	24	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2494	24	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2495	24	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2496	24	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2497	24	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2498	24	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2499	24	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2500	24	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2501	24	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2502	24	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2503	24	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3577	9	母版补充现场观察	3	design_file_no	设计文件/图纸编号	text	委托资料未提供		f	f	t	6
2505	24	硬度和试样表面确认	2	method	试验力级别	text	HV10		f	f	f	2
2506	24	硬度和试样表面确认	2	test_force	试验力/N	number	98.07		f	f	f	3
2507	24	硬度和试样表面确认	2	dwell_time	保荷时间/s	number	15.0		f	f	f	4
2508	24	硬度和试样表面确认	2	standard_block_no	标准硬度块编号	text	BPGL-B007		f	f	f	5
2509	24	硬度和试样表面确认	2	standard_block_nominal	标准硬度块标称值/HV	number	466.0		f	f	f	6
2510	24	硬度和试样表面确认	2	standard_block_due	标准硬度块有效期	date			f	f	f	7
2511	24	硬度和试样表面确认	2	standard_block_reading_1	标准硬度块实测值1/HV	number			f	f	t	8
2512	24	硬度和试样表面确认	2	standard_block_reading_2	标准硬度块实测值2/HV	number			f	f	t	9
2513	24	硬度和试样表面确认	2	standard_block_reading_3	标准硬度块实测值3/HV	number			f	f	t	10
2514	24	硬度和试样表面确认	2	standard_block_result	标准硬度块核查结果	select		合格,不合格	f	f	f	11
2515	24	硬度和试样表面确认	2	surface_condition	测试面状态	select		平整清洁,异常	f	f	f	12
2516	24	硬度和试样表面确认	2	perpendicularity	试样垂直性确认	select		符合,不符合	f	f	f	13
2517	24	硬度和试样表面确认	2	indent_measurement_method	压痕测量方式	text	切线测量		f	f	f	14
2518	24	硬度和试样表面确认	2	report_exported	硬度报告已导出	select	是	是,否	f	f	f	15
2519	24	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2520	24	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2521	24	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2522	24	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2523	24	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
2524	24	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	6
2525	24	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	7
2526	24	母版补充现场观察	3	surface_preparation_hv	测试面磨制/抛光及清洁状态	text	表面平整清洁且不影响压痕		f	f	t	8
2527	24	母版补充现场观察	3	software_version_actual	本次硬度测量软件版本	text	由设备配置核对		f	f	t	9
2528	24	母版补充现场观察	3	loading_unloading_confirmation	加载、保荷及卸载过程	select	正常	正常,异常	f	f	t	10
2529	25	环境与设备	1	test_date	检测日期	date			f	f	f	1
2530	25	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2531	25	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2532	25	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2533	25	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2534	25	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2535	25	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2536	25	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2537	25	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2538	25	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2539	25	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2540	25	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2541	25	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2542	25	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2543	25	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2544	25	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2545	25	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2546	25	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3578	9	母版补充现场观察	3	fixture_method_note	固定方式、测点布置及重复测量说明	text	固定端/中点/自由端各测3点并重复3次		f	f	t	7
3579	10	环境与设备	1	test_date	检测日期	date		[]	f	f	f	0
2549	25	影像测量参数	2	magnification	测试放大倍数	text	33倍		f	f	f	3
2550	25	影像测量参数	2	calibration_nominal	标准量块标称值/mm	number			f	f	t	4
2551	25	影像测量参数	2	calibration_measured	标准量块实测值/mm	number			f	f	t	5
2552	25	影像测量参数	2	calibration_result	校准核查结果	select		合格,不合格	f	f	f	6
2553	25	影像测量参数	2	preheat_start	设备预热开始时间	text			f	f	f	7
2554	25	影像测量参数	2	preheat_end	设备预热结束时间	text			f	f	f	8
2555	25	影像测量参数	2	measurement_points	测量点位	text	固定端、中点、自由端		f	f	f	9
2556	25	影像测量参数	2	repeat_count	每个试样重复测量次数	number	1.0		f	f	f	10
2557	25	影像测量参数	2	design_thickness	设计厚度/mm	number			f	f	t	11
2558	25	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2559	25	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2560	25	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2561	25	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2562	25	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
2563	25	母版补充现场观察	3	design_file_no	设计文件/图纸编号	text	委托资料未提供		f	f	t	6
2564	25	母版补充现场观察	3	fixture_method_note	固定方式、测点布置及重复测量说明	text	固定端/中点/自由端各测3点并重复3次		f	f	t	7
3580	10	光照、水浴和观察条件	2	source_type	发光源	select	氙灯	["氙灯","等同光源"]	f	f	f	0
3581	10	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
3582	10	光照、水浴和观察条件	2	lamp_no	氙灯编号/批号	text		[]	f	f	f	0
3583	10	环境与设备	1	temperature_before	检测前温度/℃	number	23	[]	f	f	f	0
3584	10	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	["符合","不符合"]	f	f	f	0
3585	10	环境与设备	1	temperature_after	检测后温度/℃	number	23	[]	f	f	f	0
3586	10	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	["符合","不符合"]	f	f	f	0
3587	10	光照、水浴和观察条件	2	lamp_hours	氙灯累计使用时间/h	number		[]	f	f	f	0
3588	10	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
3589	10	环境与设备	1	humidity_before	检测前湿度/%RH	number	50	[]	f	f	f	0
3590	10	光照、水浴和观察条件	2	filter_no	滤光片编号/批号	text		[]	f	f	f	0
3591	10	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	["已核对且在有效期内","存在异常"]	f	f	f	0
3592	10	环境与设备	1	humidity_after	检测后湿度/%RH	number	50	[]	f	f	f	0
3593	10	光照、水浴和观察条件	2	filter_hours	滤光片累计使用时间/h	number		[]	f	f	f	0
3594	10	环境与设备	1	detection_location	检测地点	text		[]	f	t	f	0
3595	10	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text		[]	f	t	f	0
3596	10	光照、水浴和观察条件	2	water_temperature	水浴温度/℃	number	37	[]	f	f	f	0
3597	10	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认	[]	f	f	f	0
3598	10	光照、水浴和观察条件	2	sample_illuminance	试样表面照度/lx	number	150000	[]	f	f	f	0
3599	10	环境与设备	1	start_time	实验开始时间	datetime		[]	f	f	f	0
3600	10	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	["一致","存在偏离"]	f	f	f	0
3601	10	环境与设备	1	end_time	实验结束时间	datetime		[]	f	f	f	0
3602	10	光照、水浴和观察条件	2	water_distance	试样与水面距离/mm	number	10	[]	f	f	f	0
3603	10	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	["无明显干扰","有干扰"]	f	f	f	0
3604	10	母版补充现场观察	3	control_sample_confirmation	对照试样及编号确认	select	符合	["符合","不符合"]	f	f	f	0
3605	10	光照、水浴和观察条件	2	exposure_time	照射时间/h	number	24	[]	f	f	f	0
3606	10	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	["清洁","干燥","无明显粉尘","无无关物品"]	f	f	f	0
3607	10	母版补充现场观察	3	observer_identity_note	三名观察者身份及资格记录	text	已核对三名观察者身份及颜色视觉资格	[]	f	f	f	0
3608	10	光照、水浴和观察条件	2	water_medium	水浴介质	select		["蒸馏水","去离子水"]	f	f	f	0
3609	10	母版补充现场观察	3	d65_environment_ready	D65灯箱、背景及观察环境	select	符合	["符合","不符合"]	f	f	f	0
3610	10	环境与设备	1	software	软件名称/版本	text		[]	f	f	f	0
3611	10	光照、水浴和观察条件	2	d65_illuminance	D65灯箱观察照度/lx	number	1500	[]	f	f	f	0
3612	10	母版补充现场观察	3	lamp_filter_service_note	光源/滤光片编号及使用时间核对	text	已核对且在受控使用范围内	[]	f	f	f	0
3613	10	光照、水浴和观察条件	2	background	观察背景板	select		["N5中性灰","白背景+灰背景","其他"]	f	f	f	0
3614	10	环境与设备	1	data_path	仪器原始数据保存路径	text		[]	f	f	f	0
3615	10	母版补充现场观察	3	sample_position_note	试样位置、遮盖及水位说明	text	位置、遮盖和水位符合方法要求	[]	f	f	f	0
3616	10	环境与设备	1	equipment_name	主要设备名称	text		[]	f	t	f	0
3617	10	光照、水浴和观察条件	2	observation_distance	观察距离/mm	number	250	[]	f	f	f	0
3618	10	环境与设备	1	equipment_model	设备型号/规格	text		[]	f	t	f	0
3619	10	光照、水浴和观察条件	2	single_observation_time	单次观察时间/s	number	2	[]	f	f	f	0
3620	10	光照、水浴和观察条件	2	observer_1	观察者1姓名/颜色视觉记录	text		[]	f	f	f	0
3621	10	环境与设备	1	equipment_no	设备管理编号	text		[]	f	t	f	0
3622	10	光照、水浴和观察条件	2	observer_2	观察者2姓名/颜色视觉记录	text		[]	f	f	f	0
3623	10	环境与设备	1	calibration_certificate	校准/检定证书编号	text		[]	f	t	f	0
3624	10	光照、水浴和观察条件	2	observer_3	观察者3姓名/颜色视觉记录	text		[]	f	f	f	0
3625	10	环境与设备	1	calibration_due	台账校准时间	text		[]	f	t	f	0
3626	10	环境与设备	1	equipment_status	使用前设备状态	select		["正常","异常"]	f	f	f	0
3627	10	光照、水浴和观察条件	2	observer_qualification	三名观察者颜色视觉资格	select	均已确认合格	["均已确认合格","存在未确认/不合格"]	f	f	f	0
3628	10	光照、水浴和观察条件	2	exposure_start	照射开始时间	datetime		[]	f	f	f	0
3629	10	光照、水浴和观察条件	2	exposure_end	照射结束时间	datetime		[]	f	f	f	0
3630	10	光照、水浴和观察条件	2	water_temperature_end	结束时水浴温度/℃	number		[]	f	f	f	0
3631	10	光照、水浴和观察条件	2	sample_illuminance_end	结束时试样表面照度/lx	number		[]	f	f	f	0
3632	10	光照、水浴和观察条件	2	water_distance_end	结束时水面距离/mm	number		[]	f	f	f	0
3633	10	光照、水浴和观察条件	2	lamp_box_ready	D65灯箱预热/稳定	select	已完成	["已完成","未完成"]	f	f	f	0
3634	10	光照、水浴和观察条件	2	observation_date	目视观察日期	date		[]	f	f	f	0
3635	10	光照、水浴和观察条件	2	color_monitor_1_datetime	开始·日期/时间	datetime		[]	f	f	f	0
3636	10	光照、水浴和观察条件	2	color_monitor_1_runtime	开始·累计时间/h	number	0	[]	f	f	f	0
3637	10	光照、水浴和观察条件	2	color_monitor_1_water_temperature	开始·水浴温度/℃	number	37	[]	f	f	f	0
3638	10	光照、水浴和观察条件	2	color_monitor_1_illuminance	开始·试样表面照度/lx	number	150000	[]	f	f	f	0
3639	10	光照、水浴和观察条件	2	color_monitor_1_distance	开始·水面距离/mm	number	10	[]	f	f	f	0
3640	10	光照、水浴和观察条件	2	color_monitor_1_device_status	开始·设备状态	select	正常	["正常","异常"]	f	f	f	0
3641	10	光照、水浴和观察条件	2	color_monitor_1_sample_status	开始·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3642	10	光照、水浴和观察条件	2	color_monitor_1_note	开始·备注	text		[]	f	f	f	0
3643	10	光照、水浴和观察条件	2	color_monitor_2_datetime	过程1·日期/时间	datetime		[]	f	f	f	0
3644	10	光照、水浴和观察条件	2	color_monitor_2_runtime	过程1·累计时间/h	number	4	[]	f	f	f	0
3645	10	光照、水浴和观察条件	2	color_monitor_2_water_temperature	过程1·水浴温度/℃	number	37	[]	f	f	f	0
3646	10	光照、水浴和观察条件	2	color_monitor_2_illuminance	过程1·试样表面照度/lx	number	150000	[]	f	f	f	0
3647	10	光照、水浴和观察条件	2	color_monitor_2_distance	过程1·水面距离/mm	number	10	[]	f	f	f	0
3648	10	光照、水浴和观察条件	2	color_monitor_2_device_status	过程1·设备状态	select	正常	["正常","异常"]	f	f	f	0
3649	10	光照、水浴和观察条件	2	color_monitor_2_sample_status	过程1·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3650	10	光照、水浴和观察条件	2	color_monitor_2_note	过程1·备注	text		[]	f	f	f	0
3651	10	光照、水浴和观察条件	2	color_monitor_3_datetime	过程2·日期/时间	datetime		[]	f	f	f	0
3652	10	光照、水浴和观察条件	2	color_monitor_3_runtime	过程2·累计时间/h	number	8	[]	f	f	f	0
3653	10	光照、水浴和观察条件	2	color_monitor_3_water_temperature	过程2·水浴温度/℃	number	37	[]	f	f	f	0
3654	10	光照、水浴和观察条件	2	color_monitor_3_illuminance	过程2·试样表面照度/lx	number	150000	[]	f	f	f	0
3655	10	光照、水浴和观察条件	2	color_monitor_3_distance	过程2·水面距离/mm	number	10	[]	f	f	f	0
3656	10	光照、水浴和观察条件	2	color_monitor_3_device_status	过程2·设备状态	select	正常	["正常","异常"]	f	f	f	0
3657	10	光照、水浴和观察条件	2	color_monitor_3_sample_status	过程2·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3658	10	光照、水浴和观察条件	2	color_monitor_3_note	过程2·备注	text		[]	f	f	f	0
3659	10	光照、水浴和观察条件	2	color_monitor_4_datetime	过程3·日期/时间	datetime		[]	f	f	f	0
3660	10	光照、水浴和观察条件	2	color_monitor_4_runtime	过程3·累计时间/h	number	12	[]	f	f	f	0
3661	10	光照、水浴和观察条件	2	color_monitor_4_water_temperature	过程3·水浴温度/℃	number	37	[]	f	f	f	0
3662	10	光照、水浴和观察条件	2	color_monitor_4_illuminance	过程3·试样表面照度/lx	number	150000	[]	f	f	f	0
3663	10	光照、水浴和观察条件	2	color_monitor_4_distance	过程3·水面距离/mm	number	10	[]	f	f	f	0
3664	10	光照、水浴和观察条件	2	color_monitor_4_device_status	过程3·设备状态	select	正常	["正常","异常"]	f	f	f	0
3665	10	光照、水浴和观察条件	2	color_monitor_4_sample_status	过程3·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3666	10	光照、水浴和观察条件	2	color_monitor_4_note	过程3·备注	text		[]	f	f	f	0
3667	10	光照、水浴和观察条件	2	color_monitor_5_datetime	过程4·日期/时间	datetime		[]	f	f	f	0
3668	10	光照、水浴和观察条件	2	color_monitor_5_runtime	过程4·累计时间/h	number	20	[]	f	f	f	0
3669	10	光照、水浴和观察条件	2	color_monitor_5_water_temperature	过程4·水浴温度/℃	number	37	[]	f	f	f	0
3670	10	光照、水浴和观察条件	2	color_monitor_5_illuminance	过程4·试样表面照度/lx	number	150000	[]	f	f	f	0
3671	10	光照、水浴和观察条件	2	color_monitor_5_distance	过程4·水面距离/mm	number	10	[]	f	f	f	0
3672	10	光照、水浴和观察条件	2	color_monitor_5_device_status	过程4·设备状态	select	正常	["正常","异常"]	f	f	f	0
3673	10	光照、水浴和观察条件	2	color_monitor_5_sample_status	过程4·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
3674	10	光照、水浴和观察条件	2	color_monitor_5_note	过程4·备注	text		[]	f	f	f	0
3675	10	光照、水浴和观察条件	2	color_monitor_6_datetime	结束·日期/时间	datetime		[]	f	f	f	0
3676	10	光照、水浴和观察条件	2	color_monitor_6_runtime	结束·累计时间/h	number	24	[]	f	f	f	0
3677	10	光照、水浴和观察条件	2	color_monitor_6_water_temperature	结束·水浴温度/℃	number	37	[]	f	f	f	0
2669	27	环境与设备	1	test_date	检测日期	date			f	f	f	1
2670	27	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2671	27	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2672	27	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2673	27	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2674	27	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2675	27	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2676	27	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2677	27	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2678	27	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2679	27	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2680	27	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2681	27	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2682	27	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2683	27	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2684	27	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2685	27	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2686	27	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
2687	27	检验参数	2	design_no	设计单编号	text			f	f	f	1
2688	27	检验参数	2	material	材料类型	select	氧化锆	氧化锆,钴铬合金,纯钛,二硅酸锂,其他	f	f	f	2
2689	27	检验参数	2	surface_quality	表面质量	select	合格	合格,不合格	f	f	f	3
2690	27	检验参数	2	margin_fit	边缘适合性/μm	number			f	f	f	4
2691	27	检验参数	2	contact_point	邻接关系	select	合格	合格,过紧,过松	f	f	f	5
2692	27	检验参数	2	occlusion	咬合关系	select	合格	合格,早接触,无接触	f	f	f	6
2693	27	检验参数	2	crown_height	冠高度/mm	number			f	f	f	7
2694	27	检验参数	2	crown_width	冠宽度/mm	number			f	f	f	8
2695	27	检验参数	2	wall_thickness	壁厚/mm	number			f	f	f	9
2696	27	检验参数	2	connector_area	连接体截面积/mm²	number			f	f	f	10
2697	27	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2698	27	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2699	27	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3678	10	光照、水浴和观察条件	2	color_monitor_6_illuminance	结束·试样表面照度/lx	number	150000	[]	f	f	f	0
3679	10	光照、水浴和观察条件	2	color_monitor_6_distance	结束·水面距离/mm	number	10	[]	f	f	f	0
2700	27	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2701	27	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3680	10	光照、水浴和观察条件	2	color_monitor_6_device_status	结束·设备状态	select	正常	["正常","异常"]	f	f	f	0
2703	27	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
2704	27	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
2705	28	环境与设备	1	test_date	检测日期	date			f	f	f	1
2706	28	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2707	28	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2708	28	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2709	28	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2710	28	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2711	28	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2712	28	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2713	28	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2714	28	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2715	28	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2716	28	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2717	28	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2718	28	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2719	28	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2720	28	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2721	28	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2722	28	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
2723	28	检验参数	2	design_no	设计单编号	text			f	f	f	1
2724	28	检验参数	2	material	基托材料	select	PMMA	PMMA,钴铬合金,纯钛,弹性材料,其他	f	f	f	2
2725	28	检验参数	2	contour_check	外形检查	select	合格	合格,不合格	f	f	f	3
2726	28	检验参数	2	adaptation	适合性	select	合格	合格,不合格	f	f	f	4
2727	28	检验参数	2	retention	固位力	select	合格	合格,不足,过紧	f	f	f	5
2728	28	检验参数	2	stability	稳定性	select	合格	合格,不合格	f	f	f	6
2729	28	检验参数	2	base_thickness	基托厚度/mm	number			f	f	f	7
2730	28	检验参数	2	clasp_thickness	卡环厚度/mm	number			f	f	f	8
2731	28	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2732	28	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2733	28	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2734	28	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2735	28	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3681	10	光照、水浴和观察条件	2	color_monitor_6_sample_status	结束·试样/遮盖状态	select	正常	["正常","异常"]	f	f	f	0
2737	28	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
2738	28	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
2739	29	环境与设备	1	test_date	检测日期	date			f	f	f	1
2740	29	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2741	29	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2742	29	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2743	29	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2744	29	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2745	29	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2746	29	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2747	29	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2748	29	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2749	29	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2750	29	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2751	29	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2752	29	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2753	29	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2754	29	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2755	29	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2756	29	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
2757	29	密度系统与判定依据	2	balance_internal_calibration	天平内校准结果	select	合格	合格,不合格	f	f	f	1
2758	29	密度系统与判定依据	2	density_block_no	标准密度块/核查样编号	text	BPGL-B023		f	f	f	2
3682	10	光照、水浴和观察条件	2	color_monitor_6_note	结束·备注	text		[]	f	f	f	0
2759	29	密度系统与判定依据	2	system_check_result	密度系统核查结果	select	合格	合格,不合格	f	f	f	3
2760	29	密度系统与判定依据	2	auto_calc_check	自动计算验证	select	一致	一致,不一致	f	f	f	4
2761	29	密度系统与判定依据	2	water_type	浸没液	text	三级水		f	f	f	5
2762	29	密度系统与判定依据	2	declared_density	可追溯声明密度/(g/cm³)	number			f	f	t	6
2763	29	密度系统与判定依据	2	declared_density_source	声明密度来源文件	text			f	f	t	7
2764	29	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2765	29	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2766	29	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2767	29	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2768	29	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3683	11	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
2770	29	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
2771	29	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
2772	29	母版补充现场观察	3	cleaning_confirmation	试样清洗状态确认	select	已清洗	已清洗,未清洗	f	f	t	9
2773	29	母版补充现场观察	3	buoyancy_medium_note	浸没介质（纯水）状态说明	text	纯水温度已稳定至23±0.2℃		f	f	t	10
2774	29	母版补充现场观察	3	balance_zero_check	天平调零及稳定确认	select	符合	符合,不符合	f	f	t	11
2775	29	母版补充现场观察	3	bubble_check	试样浸没气泡附着检查	select	无气泡	无气泡,有气泡	f	f	t	12
2776	29	母版补充现场观察	3	standard_block_verification	标准密度块/参考标准核查	select	符合	符合,不符合	f	f	t	13
2777	30	环境与设备	1	test_date	检测日期	date			f	f	f	1
2778	30	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2779	30	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
2780	30	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
2781	30	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
2782	30	环境与设备	1	detection_location	检测地点	text			f	t	f	6
2783	30	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
2784	30	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
2785	30	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
2786	30	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
2787	30	环境与设备	1	software	软件名称/版本	text			f	f	f	11
2788	30	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
2789	30	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
2790	30	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
2791	30	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
2792	30	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
2793	30	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
2794	30	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
2795	30	溶液、循环与观察条件	2	immersion_device_no	循环浸泡仪管理编号	text	BPGL-A043		f	f	f	1
2796	30	溶液、循环与观察条件	2	solution_concentration	硫化钠溶液浓度/(mol/L)	number	0.1		f	f	f	2
2797	30	溶液、循环与观察条件	2	solution_mass_initial	初始批Na₂S·9H₂O称量/g	number	22.3		f	f	t	3
2798	30	溶液、循环与观察条件	2	solution_mass_24h	24 h批称量/g	number	22.3		f	f	t	4
2799	30	溶液、循环与观察条件	2	solution_mass_48h	48 h批称量/g	number	22.3		f	f	t	5
2800	30	溶液、循环与观察条件	2	bath_temperature	试验温度/℃	number	23.0		f	f	t	6
2801	30	溶液、循环与观察条件	2	cycle_immersion_seconds	每分钟浸泡时间/s	number	12.5		f	f	t	7
2802	30	溶液、循环与观察条件	2	total_duration	总试验时间/h	number	72.0		f	f	t	8
2803	30	溶液、循环与观察条件	2	solution_change_24h	第一次换液时间/h	number	24.0		f	f	t	9
2804	30	溶液、循环与观察条件	2	solution_change_48h	第二次换液时间/h	number	48.0		f	f	t	10
2805	30	溶液、循环与观察条件	2	observation_illuminance	观察照度/lx	number	1000.0		f	f	t	11
2806	30	溶液、循环与观察条件	2	observation_distance	观察距离/mm	number	250.0		f	f	t	12
2807	30	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
2808	30	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
2809	30	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
2810	30	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
2811	30	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3684	11	环境与设备	1	test_date	检测日期	date			f	f	f	1
2813	30	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
3685	11	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
2814	30	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
2815	30	母版补充现场观察	3	solution_freshness	硫化钠溶液新鲜度及保存状态	select	新鲜配制	新鲜配制,保存期内	f	f	t	9
2816	30	母版补充现场观察	3	ph_verification	溶液pH确认	select	符合	符合,不符合	f	f	t	10
2817	30	母版补充现场观察	3	immersion_cycle_note	交替浸没循环状态确认	text	10-15次/min交替浸没，运转正常		f	f	t	11
2818	30	母版补充现场观察	3	observation_lighting	观察光源及照度确认	select	符合	符合,不符合	f	f	t	12
2819	30	母版补充现场观察	3	observer_qualification	三名观察者资格确认	select	符合	符合,不符合	f	f	t	13
2820	30	母版补充现场观察	3	temperature_stability	恒温控制确认	select	稳定	稳定,波动超限	f	f	t	14
3686	11	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
3687	11	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
3688	11	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
3689	11	环境与设备	1	detection_location	检测地点	text			f	t	f	6
3690	11	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
3691	11	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
3692	11	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
3693	11	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
3694	11	环境与设备	1	software	软件名称/版本	text			f	f	f	11
3695	11	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
3696	11	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
3697	11	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
3698	11	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
3699	11	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
3700	11	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
3701	11	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3702	11	检验参数	2	design_no	设计单编号	text			f	f	f	1
3703	11	检验参数	2	material	材料类型	select	氧化锆	氧化锆,钴铬合金,纯钛,二硅酸锂,其他	f	f	f	2
3704	11	检验参数	2	surface_quality	表面质量	select	合格	合格,不合格	f	f	f	3
3705	11	检验参数	2	margin_fit	边缘适合性/μm	number			f	f	f	4
3706	11	检验参数	2	contact_point	邻接关系	select	合格	合格,过紧,过松	f	f	f	5
3707	11	检验参数	2	occlusion	咬合关系	select	合格	合格,早接触,无接触	f	f	f	6
3708	11	检验参数	2	crown_height	冠高度/mm	number			f	f	f	7
3709	11	检验参数	2	crown_width	冠宽度/mm	number			f	f	f	8
3710	11	检验参数	2	wall_thickness	壁厚/mm	number			f	f	f	9
3711	11	检验参数	2	connector_area	连接体截面积/mm²	number			f	f	f	10
3712	11	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
3713	11	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
3714	11	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3715	11	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
3716	11	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3717	11	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
3718	11	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
3719	12	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
3720	12	环境与设备	1	test_date	检测日期	date			f	f	f	1
3721	12	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
3722	12	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
3723	12	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
3724	12	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
3725	12	环境与设备	1	detection_location	检测地点	text			f	t	f	6
3726	12	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
3727	12	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
3728	12	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
3729	12	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
3730	12	环境与设备	1	software	软件名称/版本	text			f	f	f	11
3731	12	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
3732	12	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
3733	12	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
3734	12	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
3735	12	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
3736	12	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
3737	12	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3738	12	检验参数	2	design_no	设计单编号	text			f	f	f	1
3739	12	检验参数	2	material	基托材料	select	PMMA	PMMA,钴铬合金,纯钛,弹性材料,其他	f	f	f	2
3747	12	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
3748	12	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3749	12	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
3750	12	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3751	12	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
3752	12	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
3753	13	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
3754	13	环境与设备	1	test_date	检测日期	date			f	f	f	1
3755	13	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
3756	13	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
3757	13	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
3758	13	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
3759	13	环境与设备	1	detection_location	检测地点	text			f	t	f	6
3760	13	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
3761	13	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
3762	13	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
3763	13	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
3764	13	环境与设备	1	software	软件名称/版本	text			f	f	f	11
3765	13	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
3766	13	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
3767	13	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
3768	13	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
3769	13	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
3770	13	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
3771	13	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3772	13	密度系统与判定依据	2	balance_internal_calibration	天平内校准结果	select	合格	合格,不合格	f	f	f	1
3773	13	密度系统与判定依据	2	density_block_no	标准密度块/核查样编号	text	BPGL-B023		f	f	f	2
3774	13	密度系统与判定依据	2	system_check_result	密度系统核查结果	select	合格	合格,不合格	f	f	f	3
3775	13	密度系统与判定依据	2	auto_calc_check	自动计算验证	select	一致	一致,不一致	f	f	f	4
3776	13	密度系统与判定依据	2	water_type	浸没液	text	三级水		f	f	f	5
3777	13	密度系统与判定依据	2	declared_density	可追溯声明密度/(g/cm³)	number			f	f	t	6
3778	13	密度系统与判定依据	2	declared_density_source	声明密度来源文件	text			f	f	t	7
3779	13	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
3780	13	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
3781	13	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3782	13	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
3783	13	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3784	13	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
3785	13	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
3786	13	母版补充现场观察	3	cleaning_confirmation	试样清洗状态确认	select	已清洗	已清洗,未清洗	f	f	t	9
3787	13	母版补充现场观察	3	buoyancy_medium_note	浸没介质（纯水）状态说明	text	纯水温度已稳定至23±0.2℃		f	f	t	10
3788	13	母版补充现场观察	3	balance_zero_check	天平调零及稳定确认	select	符合	符合,不符合	f	f	t	11
3789	13	母版补充现场观察	3	bubble_check	试样浸没气泡附着检查	select	无气泡	无气泡,有气泡	f	f	t	12
3790	13	母版补充现场观察	3	standard_block_verification	标准密度块/参考标准核查	select	符合	符合,不符合	f	f	t	13
3791	14	母版补充现场观察	3	sample_production_date	样品生产日期/批次日期	text	\N		f	t	f	6
3792	14	环境与设备	1	test_date	检测日期	date			f	f	f	1
3793	14	环境与设备	1	temperature_before	检测前温度/℃	number	23.0		f	f	t	2
3794	14	环境与设备	1	temperature_after	检测后温度/℃	number	23.0		f	f	t	3
3795	14	环境与设备	1	humidity_before	检测前湿度/%RH	number	50.0		f	f	t	4
3796	14	环境与设备	1	humidity_after	检测后湿度/%RH	number	50.0		f	f	t	5
3797	14	环境与设备	1	detection_location	检测地点	text			f	t	f	6
3798	14	环境与设备	1	start_time	实验开始时间	datetime			f	f	t	7
3799	14	环境与设备	1	end_time	实验结束时间	datetime			f	f	t	8
3800	14	环境与设备	1	environment_interference	振动/气流影响	select	无明显干扰	无明显干扰,有干扰	f	f	f	9
3801	14	环境与设备	1	work_area_status	试验区域状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	f	10
3802	14	环境与设备	1	software	软件名称/版本	text			f	f	f	11
3803	14	环境与设备	1	data_path	仪器原始数据保存路径	text			f	f	f	12
3804	14	环境与设备	1	equipment_name	主要设备名称	text			f	t	f	13
3805	14	环境与设备	1	equipment_model	设备型号/规格	text			f	t	f	14
3806	14	环境与设备	1	equipment_no	设备管理编号	text			f	t	f	15
3807	14	环境与设备	1	calibration_certificate	校准/检定证书编号	text			f	t	f	16
3808	14	环境与设备	1	calibration_due	台账校准时间	text			f	t	f	17
3809	14	环境与设备	1	equipment_status	使用前设备状态	select		正常,异常	f	f	f	18
3810	14	溶液、循环与观察条件	2	immersion_device_no	循环浸泡仪管理编号	text	BPGL-A043		f	f	f	1
3811	14	溶液、循环与观察条件	2	solution_concentration	硫化钠溶液浓度/(mol/L)	number	0.1		f	f	f	2
3812	14	溶液、循环与观察条件	2	solution_mass_initial	初始批Na₂S·9H₂O称量/g	number	22.3		f	f	t	3
3813	14	溶液、循环与观察条件	2	solution_mass_24h	24 h批称量/g	number	22.3		f	f	t	4
3814	14	溶液、循环与观察条件	2	solution_mass_48h	48 h批称量/g	number	22.3		f	f	t	5
3815	14	溶液、循环与观察条件	2	bath_temperature	试验温度/℃	number	23.0		f	f	t	6
3816	14	溶液、循环与观察条件	2	cycle_immersion_seconds	每分钟浸泡时间/s	number	12.5		f	f	t	7
3817	14	溶液、循环与观察条件	2	total_duration	总试验时间/h	number	72.0		f	f	t	8
3818	14	溶液、循环与观察条件	2	solution_change_24h	第一次换液时间/h	number	24.0		f	f	t	9
3819	14	溶液、循环与观察条件	2	solution_change_48h	第二次换液时间/h	number	48.0		f	f	t	10
3820	14	溶液、循环与观察条件	2	observation_illuminance	观察照度/lx	number	1000.0		f	f	t	11
3821	14	溶液、循环与观察条件	2	observation_distance	观察距离/mm	number	250.0		f	f	t	12
3822	14	母版补充现场观察	3	temperature_compliance	本次温度条件是否符合	select	符合	符合,不符合	f	f	t	1
3823	14	母版补充现场观察	3	humidity_compliance	本次湿度条件是否符合	select	符合	符合,不符合	f	f	t	2
3824	14	母版补充现场观察	3	interference_compliance	环境干扰控制是否符合	select	符合	符合,不符合	f	f	t	3
3825	14	母版补充现场观察	3	work_area_condition	工作区域实际状态	multiselect	清洁,干燥,无明显粉尘,无无关物品	清洁,干燥,无明显粉尘,无无关物品	f	f	t	4
3826	14	母版补充现场观察	3	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	select	已核对且在有效期内	已核对且在有效期内,存在异常	f	f	t	5
3827	14	母版补充现场观察	3	sample_preparation_actual	本次样品制备及表面状态说明	text	已按方法要求确认		f	f	t	7
3828	14	母版补充现场观察	3	method_execution_confirmation	本次操作与受控方法一致性	select	一致	一致,存在偏离	f	f	t	8
3829	14	母版补充现场观察	3	solution_freshness	硫化钠溶液新鲜度及保存状态	select	新鲜配制	新鲜配制,保存期内	f	f	t	9
3830	14	母版补充现场观察	3	ph_verification	溶液pH确认	select	符合	符合,不符合	f	f	t	10
3831	14	母版补充现场观察	3	immersion_cycle_note	交替浸没循环状态确认	text	10-15次/min交替浸没，运转正常		f	f	t	11
3832	14	母版补充现场观察	3	observation_lighting	观察光源及照度确认	select	符合	符合,不符合	f	f	t	12
3833	14	母版补充现场观察	3	observer_qualification	三名观察者资格确认	select	符合	符合,不符合	f	f	t	13
3834	14	母版补充现场观察	3	temperature_stability	恒温控制确认	select	稳定	稳定,波动超限	f	f	t	14
\.


--
-- Data for Name: experiment_config_photo_checkpoints; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experiment_config_photo_checkpoints (id, config_id, checkpoint_code, checkpoint_label, is_required, is_sample_level, checkpoint_group, sort_order) FROM stdin;
537	17	ROUGH_POINT_1	测量点①拍照	t	t	测量点	0
538	17	ROUGH_POINT_2	测量点②拍照	t	t	测量点	0
539	17	ROUGH_POINT_3	测量点③拍照	t	t	测量点	0
540	17	ROUGH_CURVE_RESULT	测量曲线、计算设置与结果界面	t	f	结果界面	0
640	3	ENV	实验开始温湿度表	f	f	环境与设备	0
641	3	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	0
642	3	DEVICE	设备编号/铭牌	f	f	环境与设备	0
643	3	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	0
561	1	ROUGH_POINT_1	测量点①拍照	t	t	测量点	0
562	1	ROUGH_POINT_2	测量点②拍照	t	t	测量点	0
563	1	ROUGH_POINT_3	测量点③拍照	t	t	测量点	0
644	3	SETUP	样品安装、装夹或放置状态	f	t	样品状态	0
645	3	RESULT	最终读数、曲线或结果界面	f	f	结果界面	0
646	3	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	0
647	3	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	0
648	3	IQI_POSITION	样品与孔形像质计摆放	f	f	装夹与核查	0
649	3	EXPOSURE	曝光参数界面	f	f	环境与设备	0
650	3	RADIOGRAPH	原始X射线成像画面	t	t	结果界面	0
651	3	ROI	ROI位置及灰度值	t	t	结果界面	0
283	18	MC_K_VALUE	试样K值拍照	t	t	结果界面	1
284	18	MC_REPORT	报告拍照	t	t	结果界面	2
285	19	ENV	实验开始温湿度表	f	f	环境与设备	1
286	19	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
287	19	DEVICE	设备编号/铭牌	f	f	环境与设备	3
288	19	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
289	19	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
290	19	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
291	19	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
292	19	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
293	19	IQI_POSITION	样品与孔形像质计摆放	f	f	装夹与核查	9
294	19	EXPOSURE	曝光参数界面	f	f	环境与设备	10
295	19	RADIOGRAPH	原始X射线成像画面	t	t	结果界面	11
296	19	ROI	ROI位置及灰度值	t	t	结果界面	12
297	20	ENV	实验开始温湿度表	f	f	环境与设备	1
298	20	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
299	20	DEVICE	设备编号/铭牌	f	f	环境与设备	3
300	20	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
301	20	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
302	20	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
303	20	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
304	20	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
305	20	H1_BASELINE	切割前基准线到自由端中点距离	t	t	结果界面	9
306	20	H2_BASELINE	切割后基准线到自由端中点距离	t	t	结果界面	10
307	20	WARP_REPORT_1	试验报告拍照①	t	f	结果界面	11
308	20	WARP_REPORT_2	试验报告拍照②	t	f	结果界面	12
309	20	WARP_REPORT_3	试验报告拍照③	t	f	结果界面	13
310	21	CTE_PARAM_SET	试验参数设定拍照	t	f	环境与设备	1
311	21	CTE_REPORT	样品试验报告拍照	t	f	结果界面	2
312	22	ENV	实验开始温湿度表	f	f	环境与设备	1
313	22	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
314	22	DEVICE	设备编号/铭牌	f	f	环境与设备	3
315	22	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
316	22	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
317	22	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
318	22	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
319	22	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
320	22	SHOCK_BEFORE	试验前试样拍照	t	t	样品状态	9
321	22	SHOCK_AFTER	试验后试样拍照	t	t	样品状态	10
322	22	OVEN_TEMP	烘箱100±2℃实测温度	f	f	环境与设备	11
323	22	ICE_TEMP_START	试验前冰水1±1℃温度	f	f	环境与设备	12
324	22	ICE_TEMP_PROCESS	试验中每15分钟冰水复测读数	f	f	环境与设备	13
325	22	FIRST_HEAT	第一次加热开始/结束时间与温度	f	f	过程记录	14
326	22	TRANSFER_COLD	急冷转移、浸没状态与时间	f	f	过程记录	15
327	22	SECOND_HEAT	第二次加热时间与温度	f	f	过程记录	16
328	22	COOL_TEMP	自然冷却后样品表面23±2℃	f	f	过程记录	17
329	22	INSPECTION_LIGHT	外观检查光照度≥1000 lx	f	f	核查与设备	18
330	22	DAMAGE	逐颗裂纹、崩瓷或破损检查结果	f	t	结果界面	19
331	23	BEND_REPORT	报告拍照	t	t	结果界面	1
332	24	HV_LOAD_TIME	载荷和保荷时间	t	f	环境与设备	1
333	24	HV_REPORT_1	报告拍照①	t	t	结果界面	2
334	24	HV_REPORT_2	报告拍照②	t	t	结果界面	3
335	25	FIXED_DIST_1	固定端距离拍照①	t	t	测量点	1
336	25	FIXED_DIST_2	固定端距离拍照②	t	t	测量点	2
337	25	FIXED_DIST_3	固定端距离拍照③	t	t	测量点	3
338	25	MID_DIST_1	中间距离拍照①	t	t	测量点	4
339	25	MID_DIST_2	中间距离拍照②	t	t	测量点	5
340	25	MID_DIST_3	中间距离拍照③	t	t	测量点	6
341	25	FREE_END_1	自由端拍照①	t	t	测量点	7
342	25	FREE_END_2	自由端拍照②	t	t	测量点	8
343	25	FREE_END_3	自由端拍照③	t	t	测量点	9
344	25	THICK_REPORT	报告拍照	t	t	结果界面	10
355	27	ENV	实验开始温湿度表	f	f	环境与设备	1
356	27	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
357	27	DEVICE	设备编号/铭牌	f	f	环境与设备	3
358	27	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
359	27	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
360	27	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
361	27	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
362	27	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
363	27	DESIGN_TRACE	设计单、模型及原材料追溯核查	t	f	装夹与核查	9
364	27	FIXED_DENTURE_RESULT	表面、适合性、咬合及尺寸综合检验结果	t	t	结果界面	10
365	27	MICRO_RESULT	粗糙度或孔隙度显微检查结果	f	f	结果界面	11
366	28	ENV	实验开始温湿度表	f	f	环境与设备	1
367	28	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
368	28	DEVICE	设备编号/铭牌	f	f	环境与设备	3
369	28	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
370	28	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
371	28	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
372	28	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
373	28	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
374	28	DESIGN_TRACE	设计单、模型及原材料追溯核查	t	f	装夹与核查	9
460	6	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
461	6	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
462	6	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
463	6	SHOCK_BEFORE	试验前试样拍照	t	t	样品状态	9
464	6	SHOCK_AFTER	试验后试样拍照	t	t	样品状态	10
465	6	OVEN_TEMP	烘箱100±2℃实测温度	f	f	环境与设备	11
466	6	ICE_TEMP_START	试验前冰水1±1℃温度	f	f	环境与设备	12
467	6	ICE_TEMP_PROCESS	试验中每15分钟冰水复测读数	f	f	环境与设备	13
468	6	FIRST_HEAT	第一次加热开始/结束时间与温度	f	f	过程记录	14
469	6	TRANSFER_COLD	急冷转移、浸没状态与时间	f	f	过程记录	15
375	28	REMOVABLE_DENTURE_RESULT	外形、适合性、厚度及咬合综合检验结果	t	t	结果界面	10
376	28	XRAY_RESULT	金属内部质量X射线结果	f	t	结果界面	11
377	28	COLOR_RESULT	色泽检查结果	f	t	结果界面	12
378	29	ENV	实验开始温湿度表	f	f	环境与设备	1
379	29	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
380	29	DEVICE	设备编号/铭牌	f	f	环境与设备	3
381	29	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
382	29	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
383	29	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
384	29	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
385	29	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
386	30	ENV	实验开始温湿度表	f	f	环境与设备	1
387	30	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
388	30	DEVICE	设备编号/铭牌	f	f	环境与设备	3
389	30	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
390	30	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
391	30	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
392	30	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
393	30	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
566	2	MC_K_VALUE	试样K值拍照	t	t	结果界面	0
567	2	MC_REPORT	报告拍照	t	f	结果界面	0
412	26	ENV	实验开始温湿度表	f	f	\N	0
413	26	SAMPLE_BEFORE	实验前样品及标签	f	f	\N	0
414	26	DEVICE	设备编号/铭牌	f	f	\N	0
415	26	PARAMETERS	设备参数或软件数据界面	f	f	\N	0
416	26	SETUP	样品安装、装夹或放置状态	f	f	\N	0
417	26	RESULT	最终读数、曲线或结果界面	f	f	\N	0
418	26	SAMPLE_AFTER	实验结束后样品状态	f	f	\N	0
419	26	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	\N	0
420	26	COLOR_BEFORE	试验前试样拍照	t	f	\N	0
421	26	COLOR_AFTER	试验后试样拍照	t	f	\N	0
440	4	ENV	实验开始温湿度表	f	f	环境与设备	1
441	4	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
442	4	DEVICE	设备编号/铭牌	f	f	环境与设备	3
443	4	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
444	4	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
445	4	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
446	4	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
447	4	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
448	4	H1_BASELINE	切割前基准线到自由端中点距离	t	t	结果界面	9
449	4	H2_BASELINE	切割后基准线到自由端中点距离	t	t	结果界面	10
450	4	WARP_REPORT_1	试验报告拍照①	t	f	结果界面	11
451	4	WARP_REPORT_2	试验报告拍照②	t	f	结果界面	12
452	4	WARP_REPORT_3	试验报告拍照③	t	f	结果界面	13
453	5	CTE_PARAM_SET	试验参数设定拍照	t	f	环境与设备	1
454	5	CTE_REPORT	样品试验报告拍照	t	f	结果界面	2
455	6	ENV	实验开始温湿度表	f	f	环境与设备	1
456	6	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
457	6	DEVICE	设备编号/铭牌	f	f	环境与设备	3
458	6	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
459	6	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
470	6	SECOND_HEAT	第二次加热时间与温度	f	f	过程记录	16
471	6	COOL_TEMP	自然冷却后样品表面23±2℃	f	f	过程记录	17
472	6	INSPECTION_LIGHT	外观检查光照度≥1000 lx	f	f	核查与设备	18
473	6	DAMAGE	逐颗裂纹、崩瓷或破损检查结果	f	t	结果界面	19
474	7	BEND_REPORT	报告拍照	t	t	结果界面	1
475	8	HV_LOAD_TIME	载荷和保荷时间	t	f	环境与设备	1
476	8	HV_REPORT_1	报告拍照①	t	t	结果界面	2
477	8	HV_REPORT_2	报告拍照②	t	t	结果界面	3
478	9	FIXED_DIST_1	固定端距离拍照①	t	t	测量点	1
479	9	FIXED_DIST_2	固定端距离拍照②	t	t	测量点	2
480	9	FIXED_DIST_3	固定端距离拍照③	t	t	测量点	3
481	9	MID_DIST_1	中间距离拍照①	t	t	测量点	4
482	9	MID_DIST_2	中间距离拍照②	t	t	测量点	5
483	9	MID_DIST_3	中间距离拍照③	t	t	测量点	6
484	9	FREE_END_1	自由端拍照①	t	t	测量点	7
485	9	FREE_END_2	自由端拍照②	t	t	测量点	8
486	9	FREE_END_3	自由端拍照③	t	t	测量点	9
487	9	THICK_REPORT	报告拍照	t	t	结果界面	10
488	10	ENV	实验开始温湿度表	f	f	\N	0
489	10	SAMPLE_BEFORE	实验前样品及标签	f	f	\N	0
490	10	DEVICE	设备编号/铭牌	f	f	\N	0
491	10	PARAMETERS	设备参数或软件数据界面	f	f	\N	0
492	10	SETUP	样品安装、装夹或放置状态	f	f	\N	0
493	10	RESULT	最终读数、曲线或结果界面	f	f	\N	0
494	10	SAMPLE_AFTER	实验结束后样品状态	f	f	\N	0
495	10	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	\N	0
496	10	COLOR_BEFORE	试验前试样拍照	t	f	\N	0
497	10	COLOR_AFTER	试验后试样拍照	t	f	\N	0
498	11	ENV	实验开始温湿度表	f	f	环境与设备	1
499	11	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
500	11	DEVICE	设备编号/铭牌	f	f	环境与设备	3
501	11	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
502	11	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
503	11	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
504	11	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
505	11	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
506	11	DESIGN_TRACE	设计单、模型及原材料追溯核查	t	f	装夹与核查	9
507	11	FIXED_DENTURE_RESULT	表面、适合性、咬合及尺寸综合检验结果	t	t	结果界面	10
508	11	MICRO_RESULT	粗糙度或孔隙度显微检查结果	f	f	结果界面	11
509	12	ENV	实验开始温湿度表	f	f	环境与设备	1
510	12	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
511	12	DEVICE	设备编号/铭牌	f	f	环境与设备	3
512	12	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
513	12	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
514	12	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
515	12	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
516	12	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
517	12	DESIGN_TRACE	设计单、模型及原材料追溯核查	t	f	装夹与核查	9
518	12	REMOVABLE_DENTURE_RESULT	外形、适合性、厚度及咬合综合检验结果	t	t	结果界面	10
519	12	XRAY_RESULT	金属内部质量X射线结果	f	t	结果界面	11
520	12	COLOR_RESULT	色泽检查结果	f	t	结果界面	12
521	13	ENV	实验开始温湿度表	f	f	环境与设备	1
522	13	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
523	13	DEVICE	设备编号/铭牌	f	f	环境与设备	3
524	13	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
525	13	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
526	13	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
527	13	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
528	13	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
529	14	ENV	实验开始温湿度表	f	f	环境与设备	1
530	14	SAMPLE_BEFORE	实验前样品及标签	f	t	样品状态	2
531	14	DEVICE	设备编号/铭牌	f	f	环境与设备	3
532	14	PARAMETERS	设备参数或软件数据界面	f	f	环境与设备	4
533	14	SETUP	样品安装、装夹或放置状态	f	t	样品状态	5
534	14	RESULT	最终读数、曲线或结果界面	f	f	结果界面	6
535	14	SAMPLE_AFTER	实验结束后样品状态	f	t	样品状态	7
536	14	REPORT_PHOTO	检验报告照片区域用代表性照片	f	f	报告归档	8
\.


--
-- Data for Name: experiment_config_prechecks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experiment_config_prechecks (id, config_id, precheck_code, precheck_label, is_required, sort_order) FROM stdin;
816	17		本次温度条件是否符合	t	0
817	17		本次湿度条件是否符合	t	0
818	17		环境干扰控制是否符合	t	0
819	17		工作区域实际状态	t	0
820	17		设备证书、有效期及溯源信息核对结果	t	0
821	17		样品生产日期/批次日期	t	0
822	17		本次样品制备及表面状态说明	t	0
823	17		本次操作与受控方法一致性	t	0
824	17		Z轴正方向标识	t	0
825	17		测试面清洁状态	t	0
826	17		试样固定及工作台稳定性	t	0
827	17		实际测量线/方向说明	t	0
910	2		本次温度条件是否符合	t	0
911	2		本次湿度条件是否符合	t	0
912	2		环境干扰控制是否符合	t	0
913	2		工作区域实际状态	t	0
914	2		设备证书、有效期及溯源信息核对结果	t	0
915	2		样品生产日期/批次日期	t	0
916	2		本次样品制备及表面状态说明	t	0
917	2		本次操作与受控方法一致性	t	0
918	2		试样居中及跨距确认	t	0
919	2		裂纹萌生/陶瓷剥离观察说明	t	0
466	18	temperature_compliance	本次温度条件是否符合	t	1
467	18	humidity_compliance	本次湿度条件是否符合	t	2
468	18	interference_compliance	环境干扰控制是否符合	t	3
469	18	work_area_condition	工作区域实际状态	t	4
470	18	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
471	18	sample_production_date	样品生产日期/批次日期	t	6
472	18	sample_preparation_actual	本次样品制备及表面状态说明	t	7
473	18	method_execution_confirmation	本次操作与受控方法一致性	t	8
474	18	centering_confirmation	试样居中及跨距确认	t	9
475	18	crack_observation_note	裂纹萌生/陶瓷剥离观察说明	t	10
476	19	temperature_compliance	本次温度条件是否符合	t	1
477	19	humidity_compliance	本次湿度条件是否符合	t	2
478	19	interference_compliance	环境干扰控制是否符合	t	3
479	19	work_area_condition	工作区域实际状态	t	4
480	19	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
481	19	sample_production_date	样品生产日期/批次日期	t	6
482	19	sample_preparation_actual	本次样品制备及表面状态说明	t	7
483	19	method_execution_confirmation	本次操作与受控方法一致性	t	8
484	19	sample_surface_xray	样品表面清洁、干燥状态	t	9
485	19	radiation_zone_clear	辐射区域无无关人员及物品	t	10
486	19	panel_iqi_position_confirmation	探测板、像质计与样品位置确认	t	11
487	19	operator_authorization	X射线操作授权确认	t	12
488	19	density_control_note	密度/灰度标准控制范围及核查说明	t	13
489	20	temperature_compliance	本次温度条件是否符合	t	1
490	20	humidity_compliance	本次湿度条件是否符合	t	2
491	20	interference_compliance	环境干扰控制是否符合	t	3
492	20	work_area_condition	工作区域实际状态	t	4
493	20	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
494	20	sample_production_date	样品生产日期/批次日期	t	6
495	20	sample_preparation_actual	本次样品制备及表面状态说明	t	7
496	20	method_execution_confirmation	本次操作与受控方法一致性	t	8
497	20	baseline_actual	切割前基准线实际确认	t	9
498	20	cutting_position_note	实际切割位置及方向说明	t	10
499	20	coolant_actual	切割过程冷却液状态	t	11
500	21	temperature_compliance	本次温度条件是否符合	t	1
501	21	humidity_compliance	本次湿度条件是否符合	t	2
502	21	interference_compliance	环境干扰控制是否符合	t	3
503	21	work_area_condition	工作区域实际状态	t	4
504	21	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
505	21	sample_production_date	样品生产日期/批次日期	t	6
506	21	sample_preparation_actual	本次样品制备及表面状态说明	t	7
507	21	method_execution_confirmation	本次操作与受控方法一致性	t	8
508	21	specimen_processing_state	试样加工及端面状态	t	9
509	21	baseline_stability_actual	启动前基线/PV稳定性	t	10
510	21	program_execution_note	升温程序实际执行确认	t	11
511	22	temperature_compliance	本次温度条件是否符合	t	1
512	22	humidity_compliance	本次湿度条件是否符合	t	2
513	22	interference_compliance	环境干扰控制是否符合	t	3
514	22	work_area_condition	工作区域实际状态	t	4
515	22	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
516	22	sample_production_date	样品生产日期/批次日期	t	6
517	22	sample_preparation_actual	本次样品制备及表面状态说明	t	7
518	22	method_execution_confirmation	本次操作与受控方法一致性	t	8
519	22	initial_appearance_actual	试验前逐件外观状态	t	9
520	22	transfer_compliance	热冷转移时间与浸没状态	t	10
521	22	inspection_condition	观察照度、放大条件及冷却状态	t	11
522	23	temperature_compliance	本次温度条件是否符合	t	1
523	23	humidity_compliance	本次湿度条件是否符合	t	2
524	23	interference_compliance	环境干扰控制是否符合	t	3
525	23	work_area_condition	工作区域实际状态	t	4
526	23	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
527	23	sample_production_date	样品生产日期/批次日期	t	6
528	23	sample_preparation_actual	本次样品制备及表面状态说明	t	7
529	23	method_execution_confirmation	本次操作与受控方法一致性	t	8
530	23	specimen_direction	试样/打印方向	t	9
531	23	fixture_centering	夹具平行、试样居中及紧固确认	t	10
532	23	zero_and_contact	力值调零及挠度计接触确认	t	11
533	24	temperature_compliance	本次温度条件是否符合	t	1
534	24	humidity_compliance	本次湿度条件是否符合	t	2
535	24	interference_compliance	环境干扰控制是否符合	t	3
536	24	work_area_condition	工作区域实际状态	t	4
537	24	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
538	24	sample_production_date	样品生产日期/批次日期	t	6
539	24	sample_preparation_actual	本次样品制备及表面状态说明	t	7
540	24	method_execution_confirmation	本次操作与受控方法一致性	t	8
541	24	surface_preparation_hv	测试面磨制/抛光及清洁状态	t	9
542	24	software_version_actual	本次硬度测量软件版本	t	10
543	24	loading_unloading_confirmation	加载、保荷及卸载过程	t	11
544	25	temperature_compliance	本次温度条件是否符合	t	1
545	25	humidity_compliance	本次湿度条件是否符合	t	2
546	25	interference_compliance	环境干扰控制是否符合	t	3
547	25	work_area_condition	工作区域实际状态	t	4
548	25	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
549	25	sample_production_date	样品生产日期/批次日期	t	6
550	25	sample_preparation_actual	本次样品制备及表面状态说明	t	7
551	25	method_execution_confirmation	本次操作与受控方法一致性	t	8
552	25	design_file_no	设计文件/图纸编号	t	9
553	25	fixture_method_note	固定方式、测点布置及重复测量说明	t	10
888	1		本次温度条件是否符合	t	0
889	1		本次湿度条件是否符合	t	0
890	1		环境干扰控制是否符合	t	0
891	1		工作区域实际状态	t	0
892	1		设备证书、有效期及溯源信息核对结果	t	0
893	1		样品生产日期/批次日期	t	0
894	1		本次样品制备及表面状态说明	t	0
895	1		本次操作与受控方法一致性	t	0
896	1		Z轴正方向标识	t	0
897	1		测试面清洁状态	t	0
898	1		试样固定及工作台稳定性	t	0
899	1		实际测量线/方向说明	t	0
567	27	temperature_compliance	本次温度条件是否符合	t	1
568	27	humidity_compliance	本次湿度条件是否符合	t	2
569	27	interference_compliance	环境干扰控制是否符合	t	3
570	27	work_area_condition	工作区域实际状态	t	4
571	27	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
572	27	sample_production_date	样品生产日期/批次日期	t	6
573	27	sample_preparation_actual	本次样品制备及表面状态说明	t	7
574	27	method_execution_confirmation	本次操作与受控方法一致性	t	8
575	28	temperature_compliance	本次温度条件是否符合	t	1
576	28	humidity_compliance	本次湿度条件是否符合	t	2
577	28	interference_compliance	环境干扰控制是否符合	t	3
578	28	work_area_condition	工作区域实际状态	t	4
579	28	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
580	28	sample_production_date	样品生产日期/批次日期	t	6
581	28	sample_preparation_actual	本次样品制备及表面状态说明	t	7
582	28	method_execution_confirmation	本次操作与受控方法一致性	t	8
583	29	temperature_compliance	本次温度条件是否符合	t	1
584	29	humidity_compliance	本次湿度条件是否符合	t	2
585	29	interference_compliance	环境干扰控制是否符合	t	3
586	29	work_area_condition	工作区域实际状态	t	4
587	29	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
588	29	sample_production_date	样品生产日期/批次日期	t	6
589	29	sample_preparation_actual	本次样品制备及表面状态说明	t	7
590	29	method_execution_confirmation	本次操作与受控方法一致性	t	8
591	29	cleaning_confirmation	试样清洗状态确认	t	9
592	29	buoyancy_medium_note	浸没介质（纯水）状态说明	t	10
593	29	balance_zero_check	天平调零及稳定确认	t	11
594	29	bubble_check	试样浸没气泡附着检查	t	12
595	29	standard_block_verification	标准密度块/参考标准核查	t	13
596	30	temperature_compliance	本次温度条件是否符合	t	1
597	30	humidity_compliance	本次湿度条件是否符合	t	2
598	30	interference_compliance	环境干扰控制是否符合	t	3
599	30	work_area_condition	工作区域实际状态	t	4
600	30	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
601	30	sample_production_date	样品生产日期/批次日期	t	6
602	30	sample_preparation_actual	本次样品制备及表面状态说明	t	7
603	30	method_execution_confirmation	本次操作与受控方法一致性	t	8
604	30	solution_freshness	硫化钠溶液新鲜度及保存状态	t	9
605	30	ph_verification	溶液pH确认	t	10
606	30	immersion_cycle_note	交替浸没循环状态确认	t	11
607	30	observation_lighting	观察光源及照度确认	t	12
608	30	observer_qualification	三名观察者资格确认	t	13
609	30	temperature_stability	恒温控制确认	t	14
647	26		本次温度条件是否符合	t	0
648	26		本次湿度条件是否符合	t	0
649	26		环境干扰控制是否符合	t	0
650	26		工作区域实际状态	t	0
651	26		设备证书、有效期及溯源信息核对结果	t	0
652	26		样品生产日期/批次日期	t	0
653	26		本次样品制备及表面状态说明	t	0
654	26		本次操作与受控方法一致性	t	0
655	26		对照试样及编号确认	t	0
656	26		三名观察者身份及资格记录	t	0
657	26		D65灯箱、背景及观察环境	t	0
658	26		光源/滤光片编号及使用时间核对	t	0
659	26		试样位置、遮盖及水位说明	t	0
695	4	temperature_compliance	本次温度条件是否符合	t	1
696	4	humidity_compliance	本次湿度条件是否符合	t	2
697	4	interference_compliance	环境干扰控制是否符合	t	3
698	4	work_area_condition	工作区域实际状态	t	4
699	4	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
700	4	sample_production_date	样品生产日期/批次日期	t	6
701	4	sample_preparation_actual	本次样品制备及表面状态说明	t	7
702	4	method_execution_confirmation	本次操作与受控方法一致性	t	8
703	4	baseline_actual	切割前基准线实际确认	t	9
704	4	cutting_position_note	实际切割位置及方向说明	t	10
705	4	coolant_actual	切割过程冷却液状态	t	11
706	5	temperature_compliance	本次温度条件是否符合	t	1
707	5	humidity_compliance	本次湿度条件是否符合	t	2
708	5	interference_compliance	环境干扰控制是否符合	t	3
709	5	work_area_condition	工作区域实际状态	t	4
710	5	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
711	5	sample_production_date	样品生产日期/批次日期	t	6
712	5	sample_preparation_actual	本次样品制备及表面状态说明	t	7
713	5	method_execution_confirmation	本次操作与受控方法一致性	t	8
714	5	specimen_processing_state	试样加工及端面状态	t	9
715	5	baseline_stability_actual	启动前基线/PV稳定性	t	10
716	5	program_execution_note	升温程序实际执行确认	t	11
717	6	temperature_compliance	本次温度条件是否符合	t	1
718	6	humidity_compliance	本次湿度条件是否符合	t	2
719	6	interference_compliance	环境干扰控制是否符合	t	3
720	6	work_area_condition	工作区域实际状态	t	4
721	6	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
722	6	sample_production_date	样品生产日期/批次日期	t	6
723	6	sample_preparation_actual	本次样品制备及表面状态说明	t	7
724	6	method_execution_confirmation	本次操作与受控方法一致性	t	8
725	6	initial_appearance_actual	试验前逐件外观状态	t	9
726	6	transfer_compliance	热冷转移时间与浸没状态	t	10
727	6	inspection_condition	观察照度、放大条件及冷却状态	t	11
728	7	temperature_compliance	本次温度条件是否符合	t	1
729	7	humidity_compliance	本次湿度条件是否符合	t	2
730	7	interference_compliance	环境干扰控制是否符合	t	3
731	7	work_area_condition	工作区域实际状态	t	4
732	7	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
733	7	sample_production_date	样品生产日期/批次日期	t	6
734	7	sample_preparation_actual	本次样品制备及表面状态说明	t	7
735	7	method_execution_confirmation	本次操作与受控方法一致性	t	8
736	7	specimen_direction	试样/打印方向	t	9
737	7	fixture_centering	夹具平行、试样居中及紧固确认	t	10
738	7	zero_and_contact	力值调零及挠度计接触确认	t	11
739	8	temperature_compliance	本次温度条件是否符合	t	1
740	8	humidity_compliance	本次湿度条件是否符合	t	2
741	8	interference_compliance	环境干扰控制是否符合	t	3
742	8	work_area_condition	工作区域实际状态	t	4
743	8	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
744	8	sample_production_date	样品生产日期/批次日期	t	6
745	8	sample_preparation_actual	本次样品制备及表面状态说明	t	7
746	8	method_execution_confirmation	本次操作与受控方法一致性	t	8
747	8	surface_preparation_hv	测试面磨制/抛光及清洁状态	t	9
748	8	software_version_actual	本次硬度测量软件版本	t	10
749	8	loading_unloading_confirmation	加载、保荷及卸载过程	t	11
750	9	temperature_compliance	本次温度条件是否符合	t	1
751	9	humidity_compliance	本次湿度条件是否符合	t	2
752	9	interference_compliance	环境干扰控制是否符合	t	3
753	9	work_area_condition	工作区域实际状态	t	4
754	9	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
755	9	sample_production_date	样品生产日期/批次日期	t	6
756	9	sample_preparation_actual	本次样品制备及表面状态说明	t	7
757	9	method_execution_confirmation	本次操作与受控方法一致性	t	8
758	9	design_file_no	设计文件/图纸编号	t	9
759	9	fixture_method_note	固定方式、测点布置及重复测量说明	t	10
760	10		本次温度条件是否符合	t	0
761	10		本次湿度条件是否符合	t	0
762	10		环境干扰控制是否符合	t	0
763	10		工作区域实际状态	t	0
764	10		设备证书、有效期及溯源信息核对结果	t	0
765	10		样品生产日期/批次日期	t	0
766	10		本次样品制备及表面状态说明	t	0
767	10		本次操作与受控方法一致性	t	0
768	10		对照试样及编号确认	t	0
769	10		三名观察者身份及资格记录	t	0
770	10		D65灯箱、背景及观察环境	t	0
771	10		光源/滤光片编号及使用时间核对	t	0
772	10		试样位置、遮盖及水位说明	t	0
773	11	temperature_compliance	本次温度条件是否符合	t	1
774	11	humidity_compliance	本次湿度条件是否符合	t	2
775	11	interference_compliance	环境干扰控制是否符合	t	3
776	11	work_area_condition	工作区域实际状态	t	4
777	11	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
778	11	sample_production_date	样品生产日期/批次日期	t	6
779	11	sample_preparation_actual	本次样品制备及表面状态说明	t	7
780	11	method_execution_confirmation	本次操作与受控方法一致性	t	8
781	12	temperature_compliance	本次温度条件是否符合	t	1
782	12	humidity_compliance	本次湿度条件是否符合	t	2
783	12	interference_compliance	环境干扰控制是否符合	t	3
784	12	work_area_condition	工作区域实际状态	t	4
785	12	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
786	12	sample_production_date	样品生产日期/批次日期	t	6
787	12	sample_preparation_actual	本次样品制备及表面状态说明	t	7
788	12	method_execution_confirmation	本次操作与受控方法一致性	t	8
789	13	temperature_compliance	本次温度条件是否符合	t	1
790	13	humidity_compliance	本次湿度条件是否符合	t	2
791	13	interference_compliance	环境干扰控制是否符合	t	3
792	13	work_area_condition	工作区域实际状态	t	4
793	13	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
794	13	sample_production_date	样品生产日期/批次日期	t	6
795	13	sample_preparation_actual	本次样品制备及表面状态说明	t	7
796	13	method_execution_confirmation	本次操作与受控方法一致性	t	8
797	13	cleaning_confirmation	试样清洗状态确认	t	9
798	13	buoyancy_medium_note	浸没介质（纯水）状态说明	t	10
799	13	balance_zero_check	天平调零及稳定确认	t	11
800	13	bubble_check	试样浸没气泡附着检查	t	12
801	13	standard_block_verification	标准密度块/参考标准核查	t	13
802	14	temperature_compliance	本次温度条件是否符合	t	1
803	14	humidity_compliance	本次湿度条件是否符合	t	2
804	14	interference_compliance	环境干扰控制是否符合	t	3
805	14	work_area_condition	工作区域实际状态	t	4
806	14	equipment_traceability_confirmation	设备证书、有效期及溯源信息核对结果	t	5
807	14	sample_production_date	样品生产日期/批次日期	t	6
808	14	sample_preparation_actual	本次样品制备及表面状态说明	t	7
809	14	method_execution_confirmation	本次操作与受控方法一致性	t	8
810	14	solution_freshness	硫化钠溶液新鲜度及保存状态	t	9
811	14	ph_verification	溶液pH确认	t	10
812	14	immersion_cycle_note	交替浸没循环状态确认	t	11
813	14	observation_lighting	观察光源及照度确认	t	12
814	14	observer_qualification	三名观察者资格确认	t	13
815	14	temperature_stability	恒温控制确认	t	14
998	3		本次温度条件是否符合	t	0
999	3		本次湿度条件是否符合	t	0
1000	3		环境干扰控制是否符合	t	0
1001	3		工作区域实际状态	t	0
1002	3		设备证书、有效期及溯源信息核对结果	t	0
1003	3		样品生产日期/批次日期	t	0
1004	3		本次样品制备及表面状态说明	t	0
1005	3		本次操作与受控方法一致性	t	0
1006	3		样品表面清洁、干燥状态	t	0
1007	3		辐射区域无无关人员及物品	t	0
1008	3		探测板、像质计与样品位置确认	t	0
1009	3		X射线操作授权确认	t	0
1010	3		密度/灰度标准控制范围及核查说明	t	0
\.


--
-- Data for Name: experiment_config_validation_rules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experiment_config_validation_rules (id, config_id, rule_type, target_field, rule_value, error_message, is_row_level) FROM stdin;
\.


--
-- Data for Name: experiment_config_versions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experiment_config_versions (id, experiment_code, version, experiment_name, method_code, standard, category, kind, default_location, sop_version, record_template_version, software, status, effective_date, note, created_by, created_at, approved_by, approved_at, extra_json) FROM stdin;
3	I003	V2.0	金属内部质量X射线灰度分析	GB 17168	YY/T1937-2024《定制式活动义齿》；	内部质量检测	xray	无损检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R005_XRAY.docx", "report_decisive_photo_codes": ["RADIOGRAPH", "ROI"]}
17	I001	V2.1	表面粗糙度试验	YY/T 1702	YY/T 1702-2020 《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	增材制造检测	rough	显微检测室	\N	\N	\N	历史	2026-08-18	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	admin	2026-08-18 14:41:26.041817+08	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "R001_表面粗糙度试验_CMA原始记录表.docx", "report_decisive_photo_codes": ["ROUGH_POINT_1", "ROUGH_CURVE_RESULT"]}
2	I002	V2.0	金属-陶瓷结合裂纹萌生试验	YY 0621.1	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》；YY 0621.1-2016 《牙科学 匹配性试验 第1部分： 金属-陶瓷体系》	力学性能检测	mc_crack	性能检测室	\N	\N	\N	现行	2026-08-15	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	admin	2026-08-15 23:53:18.869492+08	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R004_MC_CRACK.docx", "report_decisive_photo_codes": ["MC_K_VALUE", "MC_REPORT"]}
19	I003	V2.1	金属内部质量X射线灰度分析	GB 17168	YY/T1937-2024《定制式活动义齿》；	内部质量检测	xray	无损检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
4	I004	V2.0	翘曲变形试验	YY/T 1702	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	增材制造检测	warp	显微检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{}
5	I005	V2.0	热膨胀系数试验	YY 0621.1	GB 30367-2013 《牙科学 陶瓷材料》	物理性能检测	cte	性能检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R007_CTE.docx", "report_decisive_photo_codes": ["CTE_PARAM_SET", "CTE_REPORT"]}
6	I006	V2.0	陶瓷牙耐急冷急热试验	YY 0300	YY 0300-2009 《牙科学 修复用人工牙》	陶瓷材料检测	shock	性能检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R009_THERMAL_SHOCK.docx", "report_decisive_photo_codes": ["DAMAGE"]}
8	I008	V2.0	维氏硬度试验	GB/T 4340.1	GB/T 4340.1-2024《金属材料 维氏硬度试验 第1部分：试验方法》； YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	力学性能检测	hv	显微检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R011_VICKERS.docx", "report_decisive_photo_codes": ["HV_REPORT_1"]}
9	I009	V2.0	增材制造金属试样厚度测量	YY/T 1702	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	增材制造检测	thickness	显微检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R013_THICKNESS.docx", "report_decisive_photo_codes": ["FIXED_DIST_1", "MID_DIST_1", "FREE_END_1", "THICK_REPORT"]}
18	I002	V2.1	金属-陶瓷结合裂纹萌生试验	YY 0621.1	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》；YY 0621.1-2016 《牙科学 匹配性试验 第1部分： 金属-陶瓷体系》	力学性能检测	mc_crack	性能检测室	\N	\N	\N	历史	2026-08-17	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	admin	2026-08-15 23:53:18.869492+08	{}
7	I007	V2.0	弯曲性能试验	YY/T 1702	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	力学性能检测	bend	性能检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R010_BENDING.docx", "report_decisive_photo_codes": ["BEND_REPORT"]}
23	I007	V2.1	弯曲性能试验	YY/T 1702	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	力学性能检测	bend	性能检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
10	I010	V2.0	牙科材料色稳定性试验	YY 0710	YY/T 0631-2008 《牙科材料 色稳定性的测定》；YY 0270.1-2011《牙科学 基托聚合物 第1部分:义齿基托聚合物 》	物理性能检测	color	外观检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R012_COLOR_STABILITY.docx", "report_decisive_photo_codes": ["COLOR_BEFORE", "COLOR_AFTER"]}
11	I011	V2.0	定制式固定义齿综合检验	YY/T 1936	YY/T 1936-2024 《定制式固定义齿》	定制式义齿	fixed_denture	外观检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "R014_定制式固定义齿检验_CMA原始记录表.docx", "report_decisive_photo_codes": []}
12	I012	V2.0	定制式活动义齿综合检验	YY 0270.1	YY/T1937-2024《定制式活动义齿》	定制式义齿	removable_denture	外观检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "R015_定制式活动义齿检验_CMA原始记录表.docx", "report_decisive_photo_codes": []}
22	I006	V2.1	陶瓷牙耐急冷急热试验	YY 0300	YY 0300-2009 《牙科学 修复用人工牙》	陶瓷材料检测	shock	性能检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
13	I013	V2.0	激光选区熔化金属材料密度试验	YY/T 1702	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》；ISO 22674:2022《牙科学 固定和活动修复体和矫治器用金属材料》	增材制造检测	density	性能检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx", "report_decisive_photo_codes": ["DENSITY_RESULT", "DENSITY_CALIBRATION"]}
14	I014	V2.0	金属材料抗晦暗性能试验	YY 0710	YY/T1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料 》；ISO 22674:2022《牙科学 固定和活动修复体和矫治器用金属材料》；YY/T 0528-2025《牙科金属材料-腐蚀试验方法》	物理性能检测	tarnish	外观检测室	\N	\N	\N	现行	2026-08-12	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "R017_金属材料抗晦暗性能试验_CMA原始记录表.docx", "report_decisive_photo_codes": ["TARNISH_BEFORE", "TARNISH_AFTER", "TARNISH_COMPARE"]}
24	I008	V2.1	维氏硬度试验	GB/T 4340.1	GB/T 4340.1-2024《金属材料 维氏硬度试验 第1部分：试验方法》； YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	力学性能检测	hv	显微检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
25	I009	V2.1	增材制造金属试样厚度测量	YY/T 1702	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	增材制造检测	thickness	显微检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
26	I010	V2.1	牙科材料色稳定性试验	YY 0710	YY/T 0631-2008 《牙科材料 色稳定性的测定》；YY 0270.1-2011《牙科学 基托聚合物 第1部分:义齿基托聚合物 》	物理性能检测	color	外观检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "R012_牙科材料色稳定性试验_CMA原始记录表.docx", "report_decisive_photo_codes": ["COLOR_BEFORE", "COLOR_AFTER"]}
27	I011	V2.1	定制式固定义齿综合检验	YY/T 1936	YY/T 1936-2024 《定制式固定义齿》	定制式义齿	fixed_denture	外观检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
28	I012	V2.1	定制式活动义齿综合检验	YY 0270.1	YY/T1937-2024《定制式活动义齿》	定制式义齿	removable_denture	外观检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
20	I004	V2.1	翘曲变形试验	YY/T 1702	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	增材制造检测	warp	显微检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
21	I005	V2.1	热膨胀系数试验	YY 0621.1	GB 30367-2013 《牙科学 陶瓷材料》	物理性能检测	cte	性能检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
29	I013	V2.1	激光选区熔化金属材料密度试验	YY/T 1702	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》；ISO 22674:2022《牙科学 固定和活动修复体和矫治器用金属材料》	增材制造检测	density	性能检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
30	I014	V2.1	金属材料抗晦暗性能试验	YY 0710	YY/T1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料 》；ISO 22674:2022《牙科学 固定和活动修复体和矫治器用金属材料》；YY/T 0528-2025《牙科金属材料-腐蚀试验方法》	物理性能检测	tarnish	外观检测室	\N	\N	\N	历史	2026-08-14	auto-seed 首次启动自动创建 (2026-08-14)	auto_seed	2026-08-14 16:53:45.327149+08	\N	\N	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}}
1	I001	V2.0	表面粗糙度试验	YY/T 1702	YY/T 1702-2020 《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	增材制造检测	rough	显微检测室	\N	\N	\N	现行	2026-08-18	auto-seed 首次启动自动创建 (2026-08-12)	auto_seed	2026-08-12 12:23:37.598784+08	admin	2026-08-18 14:41:26.041817+08	{"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R001_ROUGHNESS.docx", "report_decisive_photo_codes": ["ROUGH_POINT_1", "ROUGH_CURVE_RESULT"]}
\.


--
-- Data for Name: experiment_equipment_bindings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experiment_equipment_bindings (experiment, management_no, binding_role, required, sort_order, note, created_at, updated_at) FROM stdin;
表面粗糙度试验	BPGL-A036	主设备	t	0	触针式粗糙度测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-B001	标准器	t	0	使用前标准块核查	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-A009	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-A010	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-A011	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-A012	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-A013	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-A014	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-A015	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-A016	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-A040	测量平台	t	0	00级大理石平台，用于粗糙度仪及小试样稳定放置	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
表面粗糙度试验	BPGL-A041	水平确认	t	0	确认平台及测量方向水平状态	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-A021	主设备	t	0	加载与力值采集	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-B009	夹具	t	0	金属-陶瓷结合试验专用夹具	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-A001	辅助量具	t	0	跨距、宽度等尺寸测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-A009	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-A010	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-A011	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-A012	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-A013	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-A014	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-A015	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属-陶瓷结合裂纹萌生试验	BPGL-A016	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A032	主设备	t	0	X射线限束与曝光	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A033	成像设备	t	0	影像输出	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A029	测量设备	t	0	黑白密度测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-B005	标准器	t	0	密度计核查	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-C001	安全监测	t	0	辐射安全监测	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-B006	辅助器具	f	0	统一成像/观察背景	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A005	辅助量具	f	0	厚度复核	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A001	辅助量具	f	0	尺寸与摆位确认	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A027	清洗设备	f	0	样品清洁	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-C002	外观检查	f	0	影像/样品辅助观察	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-C003	外观检查	f	0	影像/样品辅助观察	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A009	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A010	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A011	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A012	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A013	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A014	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A015	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属内部质量X射线灰度分析	BPGL-A016	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A026	主设备	t	0	H1、H2影像测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A018	制样设备	t	0	切割悬臂试样	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-B012	夹具	t	0	翘曲变形切割定位	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A001	辅助量具	f	0	试样尺寸确认	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A009	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A010	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A011	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A012	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A013	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A014	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A015	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
翘曲变形试验	BPGL-A016	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A020	主设备	t	0	热膨胀曲线与系数测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A034	温度测量	t	0	温度系统核查	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A001	辅助量具	t	0	试样长度测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A004	备用量具	f	0	特殊形状尺寸备用测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A030	制样设备	f	0	试样干燥	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A027	清洗设备	f	0	试样清洁	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A009	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A010	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A011	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A012	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A013	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A014	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A015	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
热膨胀系数试验	BPGL-A016	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A030	主设备	t	0	100±2℃加热	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A034	温度测量	t	0	烘箱、冰水和冷却温度确认	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-C002	外观检查	t	0	10倍检查裂纹、崩瓷和破裂	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A028	光照设备	t	0	检查区域光照	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A009	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A010	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A011	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A012	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A013	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A014	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A015	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A016	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A037	计时设备	t	0	YS-860电子秒表；两块分别用于加热/转移与浸泡计时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A038	计时设备	t	0	YS-860电子秒表；两块分别用于加热/转移与浸泡计时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
陶瓷牙耐急冷急热试验	BPGL-A039	光照确认	f	0	检查区域照度确认	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A021	主设备	t	0	加载与力值采集	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A023	位移测量	t	0	挠度测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-B008	夹具	t	0	三点弯曲加载	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A001	辅助量具	t	0	试样尺寸和跨距测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A009	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A010	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A011	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A012	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A013	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A014	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A015	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
弯曲性能试验	BPGL-A016	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A035	主设备	t	0	HV10试验	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-B007	标准器	t	0	标准硬度块核查	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A036	表面确认	f	0	测试面粗糙度实测	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A019	制样设备	f	0	测试面磨抛	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A009	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A010	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A011	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A012	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A013	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A014	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A015	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
维氏硬度试验	BPGL-A016	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
增材制造金属试样厚度测量	BPGL-A026	主设备	t	0	二次元影像法厚度测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
增材制造金属试样厚度测量	BPGL-A009	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A024	主设备	t	0	耐光色稳定性试验	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A028	光照设备	t	0	D65标准光源对色	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-B003	标准器	t	0	牙色比色参考	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-B004	标准器	f	0	基托材料比色参考	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-B006	辅助器具	t	0	统一观察背景	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A031	测量设备	t	0	试验溶液pH确认	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A025	称量设备	t	0	试剂/溶液配制	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A034	温度测量	t	0	水浴温度核查	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A009	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A010	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A011	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A012	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A013	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A014	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A015	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A016	环境监测	f	0	记录温度和相对湿度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
牙科材料色稳定性试验	BPGL-A039	光照确认	t	0	D65对色灯箱及观察区域照度确认	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式固定义齿检验	BPGL-C003	外观检查	t	0	≥2倍外观辅助检查	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式固定义齿检验	BPGL-C004	辅助检查	t	0	边缘、组织面和适合性检查	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式固定义齿检验	BPGL-A001	辅助量具	t	0	基底和交界线尺寸测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式固定义齿检验	BPGL-A028	光照设备	f	0	色泽检查适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式固定义齿检验	BPGL-B003	标准器	f	0	比色适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式固定义齿检验	BPGL-B004	标准器	f	0	基托比色适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式固定义齿检验	BPGL-A018	制样设备	f	0	孔隙度制样适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式固定义齿检验	BPGL-A002	测量设备	f	0	金相显微检查适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式固定义齿检验	BPGL-A019	制样设备	f	0	孔隙度研磨抛光适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式固定义齿检验	BPGL-B002	标准器	f	0	暴露金属粗糙度比较适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-A001	辅助量具	t	0	基托厚度和专项尺寸测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-C003	外观检查	t	0	外观、表面和适合性检查	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-B003	标准器	f	0	色泽检查适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-B004	标准器	f	0	基托色泽检查适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-A028	光照设备	f	0	D65色泽检查适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-A039	光照确认	f	0	色泽观察照度确认	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-A032	主设备	f	0	金属支架内部质量项目适用时	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-A033	成像设备	f	0	X射线图像输出	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-B024	成像设备	f	0	数位采集板	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-B016	标准器	f	0	钴铬合金孔型像质计	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-B017	标准器	f	0	钛合金孔型像质计	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-B018	标准器	f	0	纯钛孔型像质计	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-A029	测量设备	f	0	金属内部质量密度辅助判定	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-B005	标准器	f	0	黑白密度计核查	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-A018	制样设备	f	0	终止线/孔隙度水冷制样	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
定制式活动义齿检验	BPGL-B015	辅助量具	f	0	内外终止线角度测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
激光选区熔化金属材料密度试验	BPGL-A042	主设备	t	0	空气中质量、水中表观质量和自动密度	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
激光选区熔化金属材料密度试验	BPGL-B013	标准器	t	0	天平核查砝码	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
激光选区熔化金属材料密度试验	BPGL-B014	标准器	f	0	备用核查砝码	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
激光选区熔化金属材料密度试验	BPGL-B023	标准器	t	0	密度系统核查	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
激光选区熔化金属材料密度试验	BPGL-A034	温度测量	t	0	试验用水温度测量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
激光选区熔化金属材料密度试验	BPGL-A027	清洗设备	t	0	试样超声清洗2 min	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属材料抗晦暗性能试验	BPGL-A043	主设备	t	0	每分钟浸入10～15 s，连续运行72±1 h	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属材料抗晦暗性能试验	BPGL-A017	恒温设备	t	0	维持23±2 ℃	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属材料抗晦暗性能试验	BPGL-A027	清洗设备	t	0	乙醇中超声清洗2 min	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属材料抗晦暗性能试验	BPGL-A039	光照确认	t	0	观察位置照度≥1000 lx	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属材料抗晦暗性能试验	BPGL-A025	称量设备	t	0	水合硫化钠称量	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属材料抗晦暗性能试验	BPGL-C006	溶液配制	t	0	1000 mL溶液定容	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属材料抗晦暗性能试验	BPGL-C012	安全设施	t	0	硫化钠溶液配制与操作防护	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
金属材料抗晦暗性能试验	BPGL-A019	制样设备	t	0	1 μm终抛前的金相研磨抛光	2026-08-13 12:38:27.222479+08	2026-08-13 12:38:27.222479+08
\.


--
-- Data for Name: experiment_methods; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experiment_methods (experiment_code, experiment_name, method_code, standard, category, kind, enabled, sort_order, created_at, updated_at, template_code, sop_file) FROM stdin;
I007	弯曲性能试验	YY/T 1702-2020	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》		bending	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:46:25.293525+08	\N	\N
I006	陶瓷牙耐急冷急热试验	YY 0300-2009	YY 0300-2009 《牙科学 修复用人工牙》		thermal_shock	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:46:35.117642+08	\N	\N
I005	热膨胀系数试验	GB 30367-2013	GB 30367-2013 《牙科学 陶瓷材料》		cte	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:46:53.562484+08	\N	\N
I004	翘曲变形试验	YY/T 1702-2020	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》		warpage	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:47:03.110633+08	\N	\N
I003	金属内部质量X射线灰度分析	YY/T1937-2024	YY/T1937-2024《定制式活动义齿》；		xray	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:47:32.355134+08	\N	\N
I002	金属-陶瓷结合裂纹萌生试验	YY 0621.1-2016	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》；YY 0621.1-2016 《牙科学 匹配性试验 第1部分： 金属-陶瓷体系》		crack	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:47:53.169838+08	\N	\N
I001	表面粗糙度试验	YY/T 1702-2020	YY/T 1702-2020 《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》		roughness	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:48:00.876643+08	\N	\N
I014	金属材料抗晦暗性能试验	YY/T1702-2020；YY/T 0528-2025；ISO 22674:2022	YY/T1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料 》；ISO 22674:2022《牙科学 固定和活动修复体和矫治器用金属材料》；YY/T 0528-2025《牙科金属材料-腐蚀试验方法》		tarnish	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:36:07.998358+08	\N	\N
I012	定制式活动义齿检验	YY/T1937-2024	YY/T1937-2024《定制式活动义齿》		removable_denture	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:45:22.243575+08	\N	\N
I013	激光选区熔化金属材料密度试验	YY/T 1702-2020	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》；ISO 22674:2022《牙科学 固定和活动修复体和矫治器用金属材料》		density	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:45:33.587489+08	\N	\N
I011	定制式固定义齿检验	YY/T 1936-2024	YY/T 1936-2024 《定制式固定义齿》		fixed_denture	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:45:41.605307+08	\N	\N
I010	牙科材料色稳定性试验	YY/T 0631-2008	YY/T 0631-2008 《牙科材料 色稳定性的测定》；YY 0270.1-2011《牙科学 基托聚合物 第1部分:义齿基托聚合物 》		color_stability	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:45:52.620258+08	\N	\N
I009	增材制造金属试样厚度测量	YY/T 1702-2020	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》		thickness	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:46:01.564924+08	\N	\N
I008	维氏硬度试验	GB/T 4340.1-2024	GB/T 4340.1-2024《金属材料 维氏硬度试验 第1部分：试验方法》； YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》		vickers	t	0	2026-08-12 11:34:39.450008+08	2026-08-18 14:46:14.595361+08	\N	\N
\.


--
-- Data for Name: experiment_standards; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.experiment_standards (id, experiment_code, standard, enabled, sort_order, created_at, updated_at) FROM stdin;
2	I003	T/GDMDMA 0003-2020《定制式正畸矫治器》	t	1	2026-08-18 14:34:53.936177+08	2026-08-18 14:34:53.936177+08
3	I005	GB 17168-2013《牙科学 固定和活动修复用金属材料》	t	1	2026-08-18 14:35:17.350739+08	2026-08-18 14:35:17.350739+08
4	I005	ISO 22674:2022《牙科学 固定和活动修复体和矫治器用金属材料》；YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	t	2	2026-08-18 14:35:36.419557+08	2026-08-18 14:35:36.419557+08
\.


--
-- Data for Name: form_drafts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.form_drafts (session_token, page, draft_key, payload, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: hazardous_waste_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.hazardous_waste_records (disposal_no, commission_no, task_no, task_nos, sample_no, waste_type, waste_name, quantity, unit, hazard_category, disposal_method, container_no, handler, occurred_at, status, created_at, note, created_by, updated_at) FROM stdin;
\.


--
-- Data for Name: modification_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.modification_logs (id, entity_type, entity_id, actor, action, field_name, old_value, new_value, reason, created_at, commission_no) FROM stdin;
1	record	BP20260817001-T01	liuhong_test	修改	_form.em_source	说明书	检测报告		2026-08-17 15:13:22.908983+08	WT20260817001
2	record	BP20260817001-T01	liuhong_test	修改	_form.em_source_file		65432		2026-08-17 15:13:22.9106+08	WT20260817001
3	record	BP20260817001-T01	liuhong_test	修改	_form.orientation		金属面朝上、陶瓷面朝下		2026-08-17 15:13:22.911493+08	WT20260817001
4	record	BP20260817001-T01	liuhong_test	修改	_form.parallel_block_no	BGGL-B019	BPGL-B019		2026-08-17 15:13:22.912564+08	WT20260817001
5	record	BP20260817001-T01	liuhong_test	修改	_form.parallel_block_parallelism	0	4		2026-08-17 15:13:22.913896+08	WT20260817001
6	record	BP20260817001-T01	liuhong_test	修改	report_summary	BP20260817001-S01：结合强度0MPa；BP20260817001-S02：结合强度0MPa	BP20260817001-S01：结合强度576MPa；BP20260817001-S02：结合强度576MPa		2026-08-17 15:15:23.247626+08	WT20260817001
7	record	BP20260817001-T01	liuhong_test	修改	report_conclusion	不符合	符合		2026-08-17 15:15:23.249855+08	WT20260817001
8	record	BP20260817001-T01	liuhong_test	修改	_rows[0].conclusion	不符合	符合		2026-08-17 15:15:23.25097+08	WT20260817001
9	record	BP20260817001-T01	liuhong_test	修改	_rows[0].crack_position		22		2026-08-17 15:15:23.251964+08	WT20260817001
10	record	BP20260817001-T01	liuhong_test	修改	_rows[0].dm1	0	43		2026-08-17 15:15:23.252929+08	WT20260817001
11	record	BP20260817001-T01	liuhong_test	修改	_rows[0].dm2	0	32		2026-08-17 15:15:23.253845+08	WT20260817001
12	record	BP20260817001-T01	liuhong_test	修改	_rows[0].dm3	0	24		2026-08-17 15:15:23.254715+08	WT20260817001
13	record	BP20260817001-T01	liuhong_test	修改	_rows[0].dm_mean	0.0	33.0		2026-08-17 15:15:23.255869+08	WT20260817001
14	record	BP20260817001-T01	liuhong_test	修改	_rows[0].em	0	24		2026-08-17 15:15:23.256801+08	WT20260817001
15	record	BP20260817001-T01	liuhong_test	修改	_rows[0].failure_mode		22		2026-08-17 15:15:23.257542+08	WT20260817001
16	record	BP20260817001-T01	liuhong_test	修改	_rows[0].ffail	0	24		2026-08-17 15:15:23.258541+08	WT20260817001
17	record	BP20260817001-T01	liuhong_test	修改	_rows[0].k	0	24		2026-08-17 15:15:23.259429+08	WT20260817001
18	record	BP20260817001-T01	liuhong_test	修改	_rows[0].tau	0.0	576.0		2026-08-17 15:15:23.260365+08	WT20260817001
19	record	BP20260817001-T01	liuhong_test	修改	_rows[0].width	0	2		2026-08-17 15:15:23.261512+08	WT20260817001
20	record	BP20260817001-T01	liuhong_test	修改	_rows[1].conclusion	不符合	符合		2026-08-17 15:15:23.262529+08	WT20260817001
21	record	BP20260817001-T01	liuhong_test	修改	_rows[1].crack_position		4		2026-08-17 15:15:23.268956+08	WT20260817001
22	record	BP20260817001-T01	liuhong_test	修改	_rows[1].dm1	0	43		2026-08-17 15:15:23.271183+08	WT20260817001
23	record	BP20260817001-T01	liuhong_test	修改	_rows[1].dm2	0	34		2026-08-17 15:15:23.272703+08	WT20260817001
24	record	BP20260817001-T01	liuhong_test	修改	_rows[1].dm3	0	4		2026-08-17 15:15:23.273959+08	WT20260817001
25	record	BP20260817001-T01	liuhong_test	修改	_rows[1].dm_mean	0.0	27.0		2026-08-17 15:15:23.275667+08	WT20260817001
26	record	BP20260817001-T01	liuhong_test	修改	_rows[1].em	0	2		2026-08-17 15:15:23.276863+08	WT20260817001
27	record	BP20260817001-T01	liuhong_test	修改	_rows[1].failure_mode		4		2026-08-17 15:15:23.277811+08	WT20260817001
28	record	BP20260817001-T01	liuhong_test	修改	_rows[1].ffail	0	24		2026-08-17 15:15:23.278834+08	WT20260817001
29	record	BP20260817001-T01	liuhong_test	修改	_rows[1].k	0	24		2026-08-17 15:15:23.279874+08	WT20260817001
30	record	BP20260817001-T01	liuhong_test	修改	_rows[1].tau	0.0	576.0		2026-08-17 15:15:23.281135+08	WT20260817001
31	record	BP20260817001-T01	liuhong_test	修改	_rows[1].width	0	43		2026-08-17 15:15:23.282249+08	WT20260817001
32	record	BP20260817001-T01	liuhong_test	修改	_overall_status	正常完成	存在异常		2026-08-17 15:22:03.635667+08	WT20260817001
33	record	BP20260817001-T01	liuhong_test	修改	_overall_status	存在异常	正常完成		2026-08-17 15:22:26.824183+08	WT20260817001
34	record	BP20260817001-T01	liuhong_test	修改	_form.end_time		2026-08-17 15:22:25		2026-08-17 15:22:26.825252+08	WT20260817001
35	record	BP20260817001-T01	liuhong_test	修改	tester_self_check	否	是		2026-08-17 15:22:32.71799+08	WT20260817001
36	record	BP20260817001-T01	liuhong_test	修改	_task_confirm_photo	blob:http://127.0.0.1:8000/f02f7ad4-0b90-4ac5-a4e0-f793b690b6b7	/api/v1/attachments/file/BP20260817001-T01/BP20260817001-T01_152232_2.jpg		2026-08-17 15:22:32.719827+08	WT20260817001
37	report	R20260817001-T01	quality	质量审核通过	status	待质量审核	待管理员签发	\N	2026-08-17 15:37:08.730323+08	WT20260817001
38	report	R20260817001-T01	admin	批准签发	status	待管理员签发	已发布	\N	2026-08-17 15:37:34.927021+08	WT20260817001
48	experiment_method	I001	admin	修改	standard	YY/T 1702-2020；GB/T 10610-2009	YY/T 1702-2020	编辑检测项目，回写历史 0 条	2026-08-18 10:47:44.246584+08	\N
49	experiment_method	I001	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 10:47:44.277384+08	\N
50	experiment_standard	1	admin	创建	standard	\N	GB 17168-2013《牙科学 固定和活动修复用金属材料》	为 I005 新增标准变体 1016	2026-08-18 14:15:52.084746+08	\N
51	experiment_standard	1	admin	修改	standard_name	热膨胀系数试验-金属材料	热膨胀系数试验-金属材料(改)	编辑标准变体 I005	2026-08-18 14:15:52.154009+08	\N
52	experiment_standard	1	admin	删除	standard	GB 17168-2013《牙科学 固定和活动修复用金属材料》	\N	删除标准变体 1016	2026-08-18 14:15:52.160863+08	\N
53	experiment_standard	2	admin	创建	standard	\N	ISO 22674-2016	为 I005 新增标准变体 1017	2026-08-18 14:15:52.169148+08	\N
54	experiment_standard	2	admin	删除	standard	ISO 22674-2016	\N	删除标准变体 1017	2026-08-18 14:15:52.17796+08	\N
55	experiment_standard	1	admin	创建	standard	\N	GB 17168-2013《牙科学 固定和活动修复用金属材料》	为 I005 新增标准变体	2026-08-18 14:32:08.109571+08	\N
56	experiment_standard	1	admin	修改	standard	GB 17168-2013《牙科学 固定和活动修复用金属材料》	GB 17168-2013《牙科学 固定和活动修复用金属材料》(改)	编辑标准变体 I005	2026-08-18 14:32:08.189237+08	\N
57	experiment_standard	1	admin	删除	standard	GB 17168-2013《牙科学 固定和活动修复用金属材料》(改)	\N	删除标准变体	2026-08-18 14:32:08.19412+08	\N
58	experiment_standard	2	admin	创建	standard	\N	T/GDMDMA 0003-2020《定制式正畸矫治器》	为 I003 新增标准变体	2026-08-18 14:34:53.939999+08	\N
59	experiment_standard	3	admin	创建	standard	\N	GB 17168-2013《牙科学 固定和活动修复用金属材料》	为 I005 新增标准变体	2026-08-18 14:35:17.356079+08	\N
60	experiment_standard	4	admin	创建	standard	\N	ISO 22674:2022《牙科学 固定和活动修复体和矫治器用金属材料》；YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	为 I005 新增标准变体	2026-08-18 14:35:36.425587+08	\N
61	experiment_method	I014	admin	修改	method_code	YY 0710	YY/T1702-2020；YY/T 0528-2025	编辑检测项目，回写历史 0 条	2026-08-18 14:35:46.929018+08	\N
62	experiment_method	I014	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 14:35:46.932322+08	\N
63	experiment_method	I014	admin	修改	method_code	YY/T1702-2020；YY/T 0528-2025	YY/T1702-2020；YY/T 0528-2025；ISO 22674:2022	编辑检测项目，回写历史 0 条	2026-08-18 14:36:08.007914+08	\N
64	experiment_method	I012	admin	修改	method_code	YY 0270.1	YY/T1937-2024	编辑检测项目，回写历史 0 条	2026-08-18 14:45:22.253202+08	\N
65	experiment_method	I012	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 14:45:22.257613+08	\N
66	experiment_method	I013	admin	修改	method_code	YY/T 1702	YY/T 1702-2020	编辑检测项目，回写历史 2 条	2026-08-18 14:45:33.598026+08	\N
67	experiment_method	I013	admin	修改	category	\N		编辑检测项目，回写历史 2 条	2026-08-18 14:45:33.601342+08	\N
68	experiment_method	I011	admin	修改	method_code	YY/T 1936	YY/T 1936-2024	编辑检测项目，回写历史 0 条	2026-08-18 14:45:41.611036+08	\N
69	experiment_method	I011	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 14:45:41.612946+08	\N
70	experiment_method	I010	admin	修改	method_code	YY 0710	YY/T 0631-2008	编辑检测项目，回写历史 0 条	2026-08-18 14:45:52.632672+08	\N
71	experiment_method	I010	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 14:45:52.63448+08	\N
72	experiment_method	I009	admin	修改	method_code	YY/T 1702	YY/T 1702-2020	编辑检测项目，回写历史 0 条	2026-08-18 14:46:01.573844+08	\N
73	experiment_method	I009	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 14:46:01.576943+08	\N
74	experiment_method	I008	admin	修改	method_code	GB/T 4340.1	GB/T 4340.1-2024	编辑检测项目，回写历史 2 条	2026-08-18 14:46:14.601861+08	\N
75	experiment_method	I008	admin	修改	category	\N		编辑检测项目，回写历史 2 条	2026-08-18 14:46:14.603812+08	\N
76	experiment_method	I007	admin	修改	method_code	YY/T 1702	YY/T 1702-2020	编辑检测项目，回写历史 0 条	2026-08-18 14:46:25.298665+08	\N
77	experiment_method	I007	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 14:46:25.300283+08	\N
78	experiment_method	I006	admin	修改	method_code	YY 0300	YY 0300-2009	编辑检测项目，回写历史 0 条	2026-08-18 14:46:35.124235+08	\N
79	experiment_method	I006	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 14:46:35.128961+08	\N
80	experiment_method	I005	admin	修改	method_code	YY 0621.1	GB 30367-2013	编辑检测项目，回写历史 0 条	2026-08-18 14:46:53.569287+08	\N
81	experiment_method	I005	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 14:46:53.571825+08	\N
82	experiment_method	I004	admin	修改	method_code	YY/T 1702	YY/T 1702-2020	编辑检测项目，回写历史 0 条	2026-08-18 14:47:03.117753+08	\N
83	experiment_method	I004	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 14:47:03.121594+08	\N
84	experiment_method	I003	admin	修改	method_code	GB 17168	YY/T1937-2024	编辑检测项目，回写历史 0 条	2026-08-18 14:47:32.365924+08	\N
85	experiment_method	I003	admin	修改	category	\N		编辑检测项目，回写历史 0 条	2026-08-18 14:47:32.372373+08	\N
86	experiment_method	I002	admin	修改	method_code	YY 0621.1	YY 0621.1-2011	编辑检测项目，回写历史 2 条	2026-08-18 14:47:46.084996+08	\N
87	experiment_method	I002	admin	修改	category	\N		编辑检测项目，回写历史 2 条	2026-08-18 14:47:46.089783+08	\N
88	experiment_method	I002	admin	修改	method_code	YY 0621.1-2011	YY 0621.1-2016	编辑检测项目，回写历史 2 条	2026-08-18 14:47:53.17806+08	\N
89	experiment_method	I001	admin	修改	method_code	YY/T 1702	YY/T 1702-2020	编辑检测项目，回写历史 2 条	2026-08-18 14:48:00.886108+08	\N
90	record	BP20260818001-T01	liuhong_test	修改	_form.evaluation_length	4	7.5		2026-08-19 10:30:58.503235+08	WT20260818001
91	record	BP20260818001-T01	liuhong_test	修改	_form.humidity_after	50	\N		2026-08-19 10:30:58.512681+08	WT20260818001
92	record	BP20260818001-T01	liuhong_test	修改	_form.humidity_before	50	\N		2026-08-19 10:30:58.513743+08	WT20260818001
93	record	BP20260818001-T01	liuhong_test	修改	_form.humidity_compliance	符合	\N		2026-08-19 10:30:58.514676+08	WT20260818001
94	record	BP20260818001-T01	liuhong_test	修改	_form.measuring_speed	0.5	1		2026-08-19 10:30:58.51551+08	WT20260818001
95	record	BP20260818001-T01	liuhong_test	修改	_form.probe_condition		\N		2026-08-19 10:30:58.516363+08	WT20260818001
96	record	BP20260818001-T01	liuhong_test	修改	_form.repeat_check_2	0	\N		2026-08-19 10:30:58.517002+08	WT20260818001
97	record	BP20260818001-T01	liuhong_test	修改	_form.temperature_before	23	符合		2026-08-19 10:30:58.517738+08	WT20260818001
98	record	BP20260818001-T01	liuhong_test	修改	_form.temperature_compliance	符合	\N		2026-08-19 10:30:58.518403+08	WT20260818001
99	record	BP20260818001-T01	liuhong_test	修改	_rows[0].position		Z轴		2026-08-19 10:30:58.518985+08	WT20260818001
100	record	BP20260818001-T01	liuhong_test	修改	_rows[1].position		Z轴		2026-08-19 10:30:58.519649+08	WT20260818001
101	record	BP20260819001-T01	liuhong_test	修改	_rows[0].dm2	0	\N		2026-08-19 10:46:48.155474+08	WT20260819001
102	record	BP20260819001-T01	liuhong_test	修改	_rows[0].dm_mean	0.0	\N		2026-08-19 10:46:48.160317+08	WT20260819001
103	record	BP20260819001-T01	liuhong_test	修改	_rows[0].dm2	\N	0		2026-08-19 10:46:52.449658+08	WT20260819001
104	record	BP20260819001-T01	liuhong_test	修改	_rows[0].dm_mean	\N	0.0		2026-08-19 10:46:52.45083+08	WT20260819001
105	record	BP20260819001-T01	liuhong_test	修改	_rows[0].dm2	0	\N		2026-08-19 10:49:29.169708+08	WT20260819001
106	record	BP20260819001-T01	liuhong_test	修改	_rows[0].dm_mean	0.0	\N		2026-08-19 10:49:29.172081+08	WT20260819001
107	record	BP20260819001-T01	liuhong_test	修改	_rows[0].dm2	\N	0		2026-08-19 10:49:31.776704+08	WT20260819001
108	record	BP20260819001-T01	liuhong_test	修改	_rows[0].dm_mean	\N	0.0		2026-08-19 10:49:31.778034+08	WT20260819001
109	record	BP20260819001-T01	liuhong_test	修改	_rows[0].dm2	0	\N		2026-08-19 10:50:39.269778+08	WT20260819001
110	record	BP20260819001-T01	liuhong_test	修改	_rows[0].dm_mean	0.0	\N		2026-08-19 10:50:39.270985+08	WT20260819001
111	record	BP20260819005-T01	liuhong_test	修改	_form.exposure_time	110	71		2026-08-19 11:07:30.053959+08	WT20260819004
112	record	BP20260819005-T01	liuhong_test	修改	_form.focus_mode	L	S		2026-08-19 11:07:30.055045+08	WT20260819004
113	record	BP20260819005-T01	liuhong_test	修改	_form.mas	6.3	1		2026-08-19 11:07:30.055957+08	WT20260819004
114	record	BP20260819005-T01	liuhong_test	修改	_form.tube_current	56	14		2026-08-19 11:07:30.056817+08	WT20260819004
115	record	BP20260819005-T01	liuhong_test	修改	_form.tube_voltage	75	72		2026-08-19 11:07:30.057579+08	WT20260819004
116	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_1	0	1.2		2026-08-19 11:28:33.615187+08	WT20260819004
117	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_2	0	1.11		2026-08-19 11:28:33.616807+08	WT20260819004
118	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_3	0	1.21		2026-08-19 11:28:33.617661+08	WT20260819004
119	record	BP20260819005-T01	liuhong_test	修改	_form.density_meter_no		BPGL-A029;BPGL-B005		2026-08-19 11:28:33.618363+08	WT20260819004
120	record	BP20260819005-T01	liuhong_test	修改	_form.humidity_after	50	\N		2026-08-19 11:28:33.6191+08	WT20260819004
121	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_07_2	0	1		2026-08-19 11:28:33.619994+08	WT20260819004
122	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_08_2	0	-1		2026-08-19 11:28:33.620584+08	WT20260819004
123	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_09_2	0	-1		2026-08-19 11:28:33.621266+08	WT20260819004
124	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_no		BPGL-B016;BPGL-B017;BPGL-B018		2026-08-19 11:28:33.621914+08	WT20260819004
125	record	BP20260819005-T01	liuhong_test	修改	_form.panel_no		BPGL-B024		2026-08-19 11:28:33.622518+08	WT20260819004
126	record	BP20260819005-T01	liuhong_test	修改	_form.xray_model		BPGL-A032		2026-08-19 11:28:33.62307+08	WT20260819004
139	record	BP20260819005-T01	liuhong_test	修改	report_summary	BP20260819005-S01：ROI平均灰度0.4	BP20260819005-S01：ROI平均灰度0		2026-08-19 11:29:14.848335+08	WT20260819004
140	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_1	0	1.2		2026-08-19 11:29:14.849653+08	WT20260819004
141	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_2	0	1.11		2026-08-19 11:29:14.850827+08	WT20260819004
142	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_3	0	1.21		2026-08-19 11:29:14.851743+08	WT20260819004
143	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_07_2	0	1		2026-08-19 11:29:14.85267+08	WT20260819004
144	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_08_2	0	-1		2026-08-19 11:29:14.85355+08	WT20260819004
145	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_09_2	0	-1		2026-08-19 11:29:14.854436+08	WT20260819004
146	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1	1.21	0.0		2026-08-19 11:29:14.855319+08	WT20260819004
147	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1_reading1	1.08	0		2026-08-19 11:29:14.856296+08	WT20260819004
148	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1_reading2	1.31	0		2026-08-19 11:29:14.85696+08	WT20260819004
149	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1_reading3	1.24	0		2026-08-19 11:29:14.85777+08	WT20260819004
150	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi_mean	0.4	0.0		2026-08-19 11:29:14.858419+08	WT20260819004
127	record	BP20260819005-T01	liuhong_test	修改	report_summary	BP20260819005-S01：ROI平均灰度0	BP20260819005-S01：ROI平均灰度0.4		2026-08-19 11:28:48.974319+08	WT20260819004
128	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_1	1.2	0		2026-08-19 11:28:48.976477+08	WT20260819004
129	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_2	1.11	0		2026-08-19 11:28:48.978335+08	WT20260819004
130	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_3	1.21	0		2026-08-19 11:28:48.979865+08	WT20260819004
131	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_07_2	1	0		2026-08-19 11:28:48.981042+08	WT20260819004
132	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_08_2	-1	0		2026-08-19 11:28:48.98208+08	WT20260819004
133	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_09_2	-1	0		2026-08-19 11:28:48.983075+08	WT20260819004
134	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1	0.0	1.21		2026-08-19 11:28:48.983973+08	WT20260819004
135	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1_reading1	0	1.08		2026-08-19 11:28:48.984828+08	WT20260819004
136	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1_reading2	0	1.31		2026-08-19 11:28:48.985724+08	WT20260819004
137	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1_reading3	0	1.24		2026-08-19 11:28:48.986581+08	WT20260819004
138	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi_mean	0.0	0.4		2026-08-19 11:28:48.987537+08	WT20260819004
151	record	BP20260819005-T01	liuhong_test	修改	report_summary	BP20260819005-S01：ROI平均灰度0	BP20260819005-S01：ROI平均灰度0.4		2026-08-19 11:31:50.512747+08	WT20260819004
152	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_1	1.2	2		2026-08-19 11:31:50.514387+08	WT20260819004
153	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_2	1.11	2		2026-08-19 11:31:50.515524+08	WT20260819004
154	record	BP20260819005-T01	liuhong_test	修改	_form.density_measured_3	1.21	2		2026-08-19 11:31:50.516512+08	WT20260819004
155	record	BP20260819005-T01	liuhong_test	修改	_form.density_nominal	0	2		2026-08-19 11:31:50.517388+08	WT20260819004
156	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_07_2	1	0		2026-08-19 11:31:50.518072+08	WT20260819004
157	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_08_2	-1	0		2026-08-19 11:31:50.518656+08	WT20260819004
158	record	BP20260819005-T01	liuhong_test	修改	_form.iqi_gray_09_2	-1	0		2026-08-19 11:31:50.519243+08	WT20260819004
159	record	BP20260819005-T01	liuhong_test	修改	_form.radiation_safety		允许曝光		2026-08-19 11:31:50.519855+08	WT20260819004
160	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1	0.0	1.21		2026-08-19 11:31:50.520601+08	WT20260819004
161	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1_reading1	0	1.08		2026-08-19 11:31:50.521214+08	WT20260819004
162	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1_reading2	0	1.31		2026-08-19 11:31:50.52187+08	WT20260819004
163	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi1_reading3	0	1.24		2026-08-19 11:31:50.522703+08	WT20260819004
164	record	BP20260819005-T01	liuhong_test	修改	_rows[0].roi_mean	0.0	0.4		2026-08-19 11:31:50.523387+08	WT20260819004
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, recipient, title, message, entity_type, entity_id, read_at, created_at) FROM stdin;
\.


--
-- Data for Name: objection_actions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.objection_actions (id, objection_no, actor, action, comment, created_at) FROM stdin;
\.


--
-- Data for Name: objections; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.objections (objection_no, report_no, commission_no, client_name, contact, description, evidence_note, status, pathway, investigation, trace_conclusion, quality_conclusion, quality_comment, response_body, admin_decision, customer_retest_decision, retest_task_no, final_conclusion, response_sent_at, archived_at, created_at, updated_at, submitted_at, quality_inspector, disputed_items, involved_samples, application_channel, quality_evidence, quality_method_check, quality_equipment_check, quality_environment_check, quality_operation_check, quality_calculation_check, impact_scope, treatment_suggestion, retest_note, customer_contact_at, customer_contact_method, replacement_report_no, response_text, response_method, response_receipt, registered_by, investigated_at, approved_by, approved_at, sent_by, sent_at, evidence_frozen_at, evidence_snapshot) FROM stdin;
\.


--
-- Data for Name: organizations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.organizations (id, org_code, org_name, short_name, is_client, is_manufacturer, is_contract_manufacturer, address, contact, phone, credit_code, notes, enabled, created_at, updated_at) FROM stdin;
1	1	1	1	t	f	f						t	2026-08-12 12:37:54.880965+08	2026-08-12 12:37:54.880965+08
2	001	大连001义齿加工厂	001	t	t	t	大连市中山路100号	赵先生	888888	12345		t	2026-08-13 13:00:46.370303+08	2026-08-13 13:00:46.370303+08
\.


--
-- Data for Name: package_loans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.package_loans (id, package_no, sample_no, borrower, borrowed_at, purpose, detection_location, issue_note, return_condition, return_note, returned_by, returned_at, return_status, confirmed_by, confirmed_at, confirmed_location) FROM stdin;
1	BAG-BP20260817001-P01	BP20260817001-S02	liuhong_test	2026-08-17 15:09:11.022644+08	实验检测		\N	\N	\N	\N	\N	未归还	\N	\N	\N
2	BAG-BP20260817001-P01	BP20260817001-S01	liuhong_test	2026-08-17 15:09:11.022644+08	实验检测		\N	\N	\N	\N	\N	未归还	\N	\N	\N
3	BAG-BP20260818001-P01	BP20260818001-S01	liuhong_test	2026-08-18 14:38:18.237151+08	实验检测		\N	\N	\N	\N	\N	未归还	\N	\N	\N
4	BAG-BP20260818001-P01	BP20260818001-S02	liuhong_test	2026-08-18 14:38:18.237151+08	实验检测		\N	\N	\N	\N	\N	未归还	\N	\N	\N
5	BAG-BP20260819001-P01	BP20260819001-S01	liuhong_test	2026-08-19 10:36:08.049823+08	实验检测		\N	\N	\N	\N	\N	未归还	\N	\N	\N
6	BAG-BP20260819005-P01	BP20260819005-S01	liuhong_test	2026-08-19 11:01:59.097779+08	实验检测		\N	\N	\N	\N	\N	未归还	\N	\N	\N
7	BAG-BP20260819006-P01	BP20260819006-S01	liuhong_test	2026-08-19 11:51:18.299911+08	实验检测		\N	\N	\N	\N	\N	未归还	\N	\N	\N
\.


--
-- Data for Name: records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.records (id, record_no, task_no, version, experiment, owner, status, payload, template_version, sop_version, change_reason, tester_signed_at, reviewer_signed_at, quality_signed_at, created_at, updated_at) FROM stdin;
5	BP20260819001-T01	BP20260819001-T01	1	金属-陶瓷结合裂纹萌生试验	liuhong_test	草稿	{"_form": {"end_time": "", "software": "", "data_path": "", "em_source": "说明书", "test_date": "2026-08-19", "fixture_no": "BPGL-B009", "metal_name": "金瓷结合性能试样", "start_time": "2026-08-19 10:36:08", "metal_batch": "0231", "orientation": "", "equipment_no": "", "support_span": 20, "loading_speed": 1.5, "roller_radius": 1, "em_source_file": "", "equipment_name": "", "humidity_after": 50, "parallel_check": "", "calibration_due": "", "equipment_model": "", "humidity_before": 50, "equipment_status": "", "work_area_status": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "parallel_block_no": "BGGL-B019", "temperature_after": 23, "detection_location": "性能检测室", "observation_method": "目视", "temperature_before": 23, "humidity_compliance": "符合", "work_area_condition": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "centering_confirmation": "符合", "crack_observation_note": "按声响或目视结果判定", "temperature_compliance": "符合", "calibration_certificate": "", "interference_compliance": "符合", "environment_interference": "无明显干扰", "sample_preparation_actual": "已按方法要求确认", "parallel_block_parallelism": 0, "equipment_traceability_confirmation": "已核对且在有效期内"}, "_rows": [{"k": 0, "em": 0, "dm1": 0, "dm2": null, "dm3": 0, "tau": 0.0, "note": "", "ffail": 0, "width": 0, "dm_mean": null, "curve_no": "", "_showNote": false, "sample_no": "BP20260819001-S01", "conclusion": "不符合", "failure_mode": "", "crack_position": ""}], "_photos": [], "_retest": "否", "_deviation": "", "_prechecks": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "试样居中及跨距确认", "裂纹萌生/陶瓷剥离观察说明"], "_change_reason": "", "_precheck_note": "", "report_summary": "BP20260819001-S01：结合强度0MPa", "_overall_status": "正常完成", "_report_summary": "", "_template_fields": [{"key": "t0_r8_c1", "value": ""}, {"key": "t3_r1_c3", "value": "☑符合 □不符合"}, {"key": "t3_r2_c3", "value": "☑符合 □不符合"}, {"key": "t3_r3_c3", "value": "☑符合 □不符合"}, {"key": "t3_r4_c3", "value": "☑符合 □不符合"}, {"key": "t3_r5_c2", "value": "☑无毛刺 □无缺口 □无锈蚀 □无明显磨损"}, {"key": "t3_r5_c3", "value": "☑符合 □不符合"}, {"key": "t3_r6_c3", "value": "☑符合 □不符合"}, {"key": "t3_r7_c3", "value": "☑符合 □不符合"}, {"key": "t3_r8_c2", "value": "☑左右对称 ☑跨过两支撑 ☑未接触侧壁"}, {"key": "t3_r8_c3", "value": "☑符合 □不符合"}, {"key": "t3_r9_c2", "value": "☑夹具平行 ☑试样居中 ☑跨距符合"}, {"key": "t3_r9_c3", "value": "☑符合 □不符合"}, {"key": "t3_r10_c2", "value": "李红丽"}, {"key": "t4_r1_c1", "value": "试样名称：试样名称：金瓷结合性能试样；批号：0231；批号：________________"}, {"key": "t4_r2_c1", "value": "EM = / GPa；来源：□说明书 ☑检测报告 ☑注册资料 ☑质保书 ☑其他：/；文件编号：/"}, {"key": "t4_r4_c1", "value": ""}, {"key": "t5_r1_c1", "value": "☑是 □否"}, {"key": "t5_r2_c1", "value": "☑是 □否"}, {"key": "t5_r3_c1", "value": "☑是 □否"}, {"key": "t5_r4_c1", "value": "☑试样居中 ☑夹具状态正常 ☑设备状态正常"}, {"key": "t5_r5_c1", "value": "/ mm/min；要求（1.5±0.5） mm/min；☑符合 □不符合"}, {"key": "t5_r6_c1", "value": ""}, {"key": "t7_r2_c1", "value": "□否 ☑是，原因：/"}, {"key": "t7_r3_c1", "value": ""}, {"key": "t7_r4_c1", "value": "☑FastTest原始数据 ☑Office报告 ☑断裂形态照片 ☑k系数查图记录 ☑其他：/"}, {"key": "t7_r9_c2", "value": ""}], "_equipment_checks": [{"note": "", "model": "STS50K", "status": "正常", "required": true, "serial_no": "20260323020", "responsible": "", "binding_role": "主设备", "manufacturer": "厦门易仕特仪器有限公司", "management_no": "BPGL-A021", "equipment_name": "电子万能试验机", "equipment_class": "A类", "measuring_range": "（0～50）kN，0.5级；（0～2000）N，0.5级", "calibration_time": ""}, {"note": "", "model": "", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "夹具", "manufacturer": "厦门易仕特仪器有限公司", "management_no": "BPGL-B009", "equipment_name": "金瓷结合试验夹具", "equipment_class": "B类", "measuring_range": "", "calibration_time": ""}, {"note": "", "model": "", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "辅助量具", "manufacturer": "", "management_no": "BPGL-A001", "equipment_name": "数显游标卡尺", "equipment_class": "A类", "measuring_range": "（0～150）mm", "calibration_time": ""}, {"note": "", "model": "YZ-0508", "status": "正常", "required": false, "serial_no": "", "responsible": "", "binding_role": "环境监测", "manufacturer": "扬子", "management_no": "BPGL-A009", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "YZ-0508", "status": "正常", "required": false, "serial_no": "", "responsible": "", "binding_role": "环境监测", "manufacturer": "扬子", "management_no": "BPGL-A010", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "YZ-0508", "status": "正常", "required": false, "serial_no": "", "responsible": "", "binding_role": "环境监测", "manufacturer": "扬子", "management_no": "BPGL-A011", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "/", "status": "正常", "required": false, "serial_no": "/", "responsible": "", "binding_role": "环境监测", "manufacturer": "蓝骏", "management_no": "BPGL-A012", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "/", "status": "正常", "required": false, "serial_no": "/", "responsible": "", "binding_role": "环境监测", "manufacturer": "蓝骏", "management_no": "BPGL-A013", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "/", "status": "正常", "required": false, "serial_no": "/", "responsible": "", "binding_role": "环境监测", "manufacturer": "蓝骏", "management_no": "BPGL-A014", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "/", "status": "正常", "required": false, "serial_no": "/", "responsible": "", "binding_role": "环境监测", "manufacturer": "蓝骏", "management_no": "BPGL-A015", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "/", "status": "正常", "required": false, "serial_no": "/", "responsible": "", "binding_role": "环境监测", "manufacturer": "蓝骏", "management_no": "BPGL-A016", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}], "_fixed_param_mode": "按默认参数执行", "report_conclusion": "不符合", "tester_self_check": false, "_report_conclusion": "", "_tester_self_check": false, "_precheck_all_items": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "试样居中及跨距确认", "裂纹萌生/陶瓷剥离观察说明"], "_task_confirm_photo": "", "_task_confirmations": {"number_match": true, "sample_received": true, "sample_condition": true}, "_standard_block_measured": null}	A/0	A/0		\N	\N	\N	2026-08-19 10:36:44.393767+08	2026-08-19 10:50:39.259117+08
4	BP20260818001-T03	BP20260818001-T03	1	激光选区熔化金属材料密度试验	liuhong_test	草稿	{"_form": {"end_time": "", "software": "", "data_path": "", "test_date": "2026-08-18", "start_time": "2026-08-18 14:38:18", "water_type": "三级水", "bubble_check": "无气泡", "equipment_no": "", "equipment_name": "", "humidity_after": 50, "auto_calc_check": "一致", "calibration_due": "", "equipment_model": "", "humidity_before": 50, "declared_density": 0, "density_block_no": "BPGL-B023", "equipment_status": "", "work_area_status": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "temperature_after": 23, "balance_zero_check": "符合", "detection_location": "性能检测室", "temperature_before": 23, "humidity_compliance": "符合", "system_check_result": "合格", "work_area_condition": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "buoyancy_medium_note": "纯水温度已稳定至23±0.2℃", "cleaning_confirmation": "已清洗", "sample_production_date": "123", "temperature_compliance": "符合", "calibration_certificate": "", "declared_density_source": "", "interference_compliance": "符合", "environment_interference": "无明显干扰", "sample_preparation_actual": "已按方法要求确认", "standard_block_verification": "符合", "balance_internal_calibration": "合格", "method_execution_confirmation": "一致", "equipment_traceability_confirmation": "已核对且在有效期内"}, "_rows": [{"a1": 0, "a2": 0, "a3": 0, "b1": 0, "b2": 0, "b3": 0, "mean": "", "note": "", "density1": "", "density2": "", "density3": "", "_showNote": false, "sample_no": "BP20260818001-S01", "conclusion": "", "water_temp1": 0, "water_temp2": 0, "water_temp3": 0, "data_file_no": "", "auto_density1": 0, "auto_density2": 0, "auto_density3": 0, "water_density1": 0, "water_density2": 0, "water_density3": 0, "density_difference": "", "relative_deviation": ""}, {"a1": 0, "a2": 0, "a3": 0, "b1": 0, "b2": 0, "b3": 0, "mean": "", "note": "", "density1": "", "density2": "", "density3": "", "_showNote": false, "sample_no": "BP20260818001-S02", "conclusion": "", "water_temp1": 0, "water_temp2": 0, "water_temp3": 0, "data_file_no": "", "auto_density1": 0, "auto_density2": 0, "auto_density3": 0, "water_density1": 0, "water_density2": 0, "water_density3": 0, "density_difference": "", "relative_deviation": ""}], "_photos": [], "_retest": "否", "_deviation": "", "_prechecks": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "试样清洗状态确认", "浸没介质（纯水）状态说明", "天平调零及稳定确认", "试样浸没气泡附着检查", "标准密度块/参考标准核查"], "_change_reason": "", "_precheck_note": "", "report_summary": "尚未形成有效检验结果", "_overall_status": "正常完成", "_report_summary": "", "_template_fields": [{"key": "t0_r6_c3", "value": ""}, {"key": "t0_r7_c3", "value": ""}, {"key": "t0_r7_c5", "value": ""}, {"key": "t0_r8_c1", "value": ""}, {"key": "t1_r1_c2", "value": ""}, {"key": "t1_r1_c7", "value": ""}, {"key": "t1_r2_c7", "value": ""}, {"key": "t1_r3_c2", "value": ""}, {"key": "t1_r3_c7", "value": ""}, {"key": "t1_r4_c7", "value": ""}, {"key": "t1_r5_c2", "value": ""}, {"key": "t1_r5_c7", "value": ""}, {"key": "t1_r6_c2", "value": ""}, {"key": "t1_r6_c4", "value": ""}, {"key": "t1_r6_c7", "value": ""}, {"key": "t2_r0_c1", "value": ""}, {"key": "t2_r0_c3", "value": ""}, {"key": "t2_r0_c5", "value": ""}, {"key": "t2_r0_c7", "value": ""}, {"key": "t2_r1_c1", "value": ""}, {"key": "t2_r1_c3", "value": ""}, {"key": "t2_r1_c5", "value": ""}, {"key": "t2_r2_c1", "value": ""}, {"key": "t2_r2_c3", "value": ""}, {"key": "t2_r2_c5", "value": ""}, {"key": "t2_r2_c7", "value": ""}, {"key": "t3_r1_c7", "value": ""}, {"key": "t3_r2_c7", "value": ""}, {"key": "t3_r3_c7", "value": ""}, {"key": "t3_r4_c7", "value": ""}, {"key": "t3_r5_c7", "value": ""}, {"key": "t3_r6_c0", "value": ""}, {"key": "t3_r6_c2", "value": ""}, {"key": "t3_r6_c4", "value": ""}, {"key": "t3_r6_c6", "value": ""}, {"key": "t4_r4_c5", "value": ""}, {"key": "t5_r1_c2", "value": ""}, {"key": "t5_r1_c3", "value": ""}, {"key": "t5_r1_c4", "value": ""}, {"key": "t5_r2_c3", "value": ""}, {"key": "t5_r3_c3", "value": ""}, {"key": "t5_r4_c3", "value": ""}, {"key": "t5_r5_c3", "value": ""}, {"key": "t5_r5_c4", "value": ""}, {"key": "t5_r6_c3", "value": ""}, {"key": "t5_r7_c3", "value": ""}, {"key": "t5_r8_c3", "value": ""}, {"key": "t5_r8_c4", "value": ""}, {"key": "t5_r9_c3", "value": ""}, {"key": "t5_r9_c4", "value": ""}, {"key": "t6_r1_c7", "value": ""}, {"key": "t6_r1_c8", "value": ""}, {"key": "t6_r1_c9", "value": ""}, {"key": "t6_r1_c11", "value": ""}, {"key": "t6_r2_c7", "value": ""}, {"key": "t6_r2_c8", "value": ""}, {"key": "t6_r2_c9", "value": ""}, {"key": "t6_r2_c11", "value": ""}, {"key": "t6_r3_c7", "value": ""}, {"key": "t6_r3_c8", "value": ""}, {"key": "t6_r3_c9", "value": ""}, {"key": "t6_r3_c11", "value": ""}, {"key": "t6_r4_c7", "value": ""}, {"key": "t6_r4_c8", "value": ""}, {"key": "t6_r4_c9", "value": ""}, {"key": "t6_r4_c11", "value": ""}, {"key": "t6_r5_c7", "value": ""}, {"key": "t6_r5_c8", "value": ""}, {"key": "t6_r5_c9", "value": ""}, {"key": "t6_r5_c11", "value": ""}, {"key": "t6_r6_c7", "value": ""}, {"key": "t6_r6_c8", "value": ""}, {"key": "t6_r6_c9", "value": ""}, {"key": "t6_r6_c11", "value": ""}, {"key": "t6_r7_c7", "value": ""}, {"key": "t6_r7_c8", "value": ""}, {"key": "t6_r7_c9", "value": ""}, {"key": "t6_r7_c11", "value": ""}, {"key": "t6_r8_c7", "value": ""}, {"key": "t6_r8_c8", "value": ""}, {"key": "t6_r8_c9", "value": ""}, {"key": "t6_r8_c11", "value": ""}, {"key": "t6_r9_c7", "value": ""}, {"key": "t6_r9_c8", "value": ""}, {"key": "t6_r9_c9", "value": ""}, {"key": "t6_r9_c11", "value": ""}, {"key": "t6_r10_c7", "value": ""}, {"key": "t6_r10_c8", "value": ""}, {"key": "t6_r10_c9", "value": ""}, {"key": "t6_r10_c11", "value": ""}, {"key": "t6_r11_c7", "value": ""}, {"key": "t6_r11_c8", "value": ""}, {"key": "t6_r11_c9", "value": ""}, {"key": "t6_r11_c11", "value": ""}, {"key": "t6_r12_c7", "value": ""}, {"key": "t6_r12_c8", "value": ""}, {"key": "t6_r12_c9", "value": ""}, {"key": "t6_r12_c11", "value": ""}, {"key": "t6_r13_c7", "value": ""}, {"key": "t6_r13_c8", "value": ""}, {"key": "t6_r13_c9", "value": ""}, {"key": "t6_r13_c11", "value": ""}, {"key": "t6_r14_c7", "value": ""}, {"key": "t6_r14_c8", "value": ""}, {"key": "t6_r14_c9", "value": ""}, {"key": "t6_r14_c11", "value": ""}, {"key": "t6_r15_c7", "value": ""}, {"key": "t6_r15_c8", "value": ""}, {"key": "t6_r15_c9", "value": ""}, {"key": "t6_r15_c11", "value": ""}, {"key": "t6_r16_c7", "value": ""}, {"key": "t6_r16_c8", "value": ""}, {"key": "t6_r16_c9", "value": ""}, {"key": "t6_r16_c11", "value": ""}, {"key": "t6_r17_c7", "value": ""}, {"key": "t6_r17_c8", "value": ""}, {"key": "t6_r17_c9", "value": ""}, {"key": "t6_r17_c11", "value": ""}, {"key": "t6_r18_c7", "value": ""}, {"key": "t6_r18_c8", "value": ""}, {"key": "t6_r18_c9", "value": ""}, {"key": "t6_r18_c11", "value": ""}, {"key": "t7_r1_c10", "value": ""}, {"key": "t7_r2_c10", "value": ""}, {"key": "t7_r3_c10", "value": ""}, {"key": "t7_r4_c10", "value": ""}, {"key": "t7_r5_c10", "value": ""}, {"key": "t7_r6_c10", "value": ""}, {"key": "t7_r7_c3", "value": ""}, {"key": "t7_r7_c8", "value": ""}, {"key": "t7_r7_c10", "value": ""}, {"key": "t8_r1_c2", "value": ""}, {"key": "t8_r2_c2", "value": ""}, {"key": "t8_r3_c2", "value": ""}, {"key": "t8_r4_c2", "value": ""}, {"key": "t8_r5_c2", "value": ""}, {"key": "t8_r6_c2", "value": ""}, {"key": "t8_r7_c2", "value": ""}, {"key": "t8_r8_c2", "value": ""}, {"key": "t8_r9_c2", "value": ""}, {"key": "t8_r10_c2", "value": ""}, {"key": "t8_r11_c2", "value": ""}, {"key": "t9_r1_c3", "value": ""}, {"key": "t9_r2_c3", "value": ""}, {"key": "t9_r3_c3", "value": ""}, {"key": "t9_r4_c3", "value": ""}, {"key": "t9_r5_c3", "value": ""}, {"key": "t10_r0_c1", "value": ""}, {"key": "t10_r0_c3", "value": ""}, {"key": "t10_r1_c1", "value": ""}, {"key": "t10_r1_c3", "value": ""}, {"key": "t10_r2_c1", "value": ""}, {"key": "t10_r2_c3", "value": ""}, {"key": "t10_r3_c1", "value": ""}, {"key": "t10_r4_c1", "value": ""}, {"key": "t10_r5_c1", "value": ""}, {"key": "t10_r5_c3", "value": ""}, {"key": "t10_r6_c1", "value": ""}, {"key": "t10_r6_c3", "value": ""}], "_equipment_checks": [{"note": "", "model": "YET-710", "status": "正常", "required": true, "serial_no": "26056126", "responsible": "", "binding_role": "温度测量", "manufacturer": "深圳宇问测量技术有限公司", "management_no": "BPGL-A034", "equipment_name": "高精度铂电阻温度检测仪", "equipment_class": "A类", "measuring_range": "（-40～200）℃", "calibration_time": ""}, {"note": "", "model": "FA2204T·S", "status": "正常", "required": true, "serial_no": "1032606050", "responsible": "", "binding_role": "主设备", "manufacturer": "常州市幸运电子设备有限公司", "management_no": "BPGL-A042", "equipment_name": "电子密度天平", "equipment_class": "A类", "measuring_range": "（0～220）g，Ⅰ级，0.0001 g", "calibration_time": ""}, {"note": "", "model": "200 g", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "标准器", "manufacturer": "常州市幸运电子设备有限公司", "management_no": "BPGL-B013", "equipment_name": "标准砝码", "equipment_class": "B类", "measuring_range": "200 g", "calibration_time": ""}, {"note": "", "model": "200 g", "status": "正常", "required": false, "serial_no": "", "responsible": "", "binding_role": "标准器", "manufacturer": "常州市幸运电子设备有限公司", "management_no": "BPGL-B014", "equipment_name": "标准砝码", "equipment_class": "B类", "measuring_range": "200 g", "calibration_time": ""}, {"note": "", "model": "", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "标准器", "manufacturer": "", "management_no": "BPGL-B023", "equipment_name": "密度块", "equipment_class": "B类", "measuring_range": "ρ=4.506；ρ=8.67", "calibration_time": ""}, {"note": "", "model": "VGT-1620T", "status": "正常", "required": true, "serial_no": "ZZ003635F0002", "responsible": "", "binding_role": "清洗设备", "manufacturer": "广东固特超声股份有限公司", "management_no": "BPGL-A027", "equipment_name": "超声波清洗机", "equipment_class": "A类", "measuring_range": "超声频率40 kHz；超声功率50 W", "calibration_time": ""}], "_fixed_param_mode": "按默认参数执行", "report_conclusion": "仅描述结果", "tester_self_check": false, "_report_conclusion": "", "_tester_self_check": false, "_precheck_all_items": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "试样清洗状态确认", "浸没介质（纯水）状态说明", "天平调零及稳定确认", "试样浸没气泡附着检查", "标准密度块/参考标准核查"], "_task_confirm_photo": "", "_task_confirmations": {"number_match": true, "sample_received": true, "sample_condition": true}, "_standard_block_measured": null}	A/0	A/0		\N	\N	\N	2026-08-18 15:25:05.679841+08	2026-08-18 15:47:04.511861+08
1	BP20260817001-T01	BP20260817001-T01	1	金属-陶瓷结合裂纹萌生试验	liuhong_test	已锁定	{"_form": {"end_time": "2026-08-17 15:22:25", "software": "", "data_path": "", "em_source": "检测报告", "test_date": "2026-08-17", "fixture_no": "BPGL-B009", "metal_name": "金瓷结合强度试样", "start_time": "2026-08-17 15:09:11", "metal_batch": "123", "orientation": "金属面朝上、陶瓷面朝下", "equipment_no": "", "support_span": 20, "loading_speed": 1.5, "roller_radius": 1, "em_source_file": "65432", "equipment_name": "", "humidity_after": 50, "parallel_check": "符合", "calibration_due": "", "equipment_model": "", "humidity_before": 50, "equipment_status": "", "work_area_status": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "parallel_block_no": "BPGL-B019", "temperature_after": 23, "detection_location": "性能检测室", "observation_method": "目视和声响", "temperature_before": 23, "humidity_compliance": "符合", "work_area_condition": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "centering_confirmation": "符合", "crack_observation_note": "按声响或目视结果判定", "temperature_compliance": "符合", "calibration_certificate": "", "interference_compliance": "符合", "environment_interference": "无明显干扰", "sample_preparation_actual": "已按方法要求确认", "parallel_block_parallelism": 4, "equipment_traceability_confirmation": "已核对且在有效期内"}, "_rows": [{"k": 24, "em": 24, "dm1": 43, "dm2": 32, "dm3": 24, "tau": 576.0, "note": "", "ffail": 24, "width": 2, "dm_mean": 33.0, "curve_no": "", "_showNote": false, "sample_no": "BP20260817001-S01", "conclusion": "符合", "failure_mode": "22", "crack_position": "22"}, {"k": 24, "em": 2, "dm1": 43, "dm2": 34, "dm3": 4, "tau": 576.0, "note": "", "ffail": 24, "width": 43, "dm_mean": 27.0, "curve_no": "", "_showNote": false, "sample_no": "BP20260817001-S02", "conclusion": "符合", "failure_mode": "4", "crack_position": "4"}], "_photos": [{"code": "MC_K_VALUE", "label": "试样K值拍照", "samples": [], "previewUrl": "/api/v1/attachments/file/BP20260817001-T01/BP20260817001-T01_152232.jpg", "samplePhotos": {}}, {"code": "MC_REPORT", "label": "报告拍照", "samples": [], "previewUrl": "/api/v1/attachments/file/BP20260817001-T01/BP20260817001-T01_152232_1.jpg", "samplePhotos": {}}], "_retest": "否", "_deviation": "", "_prechecks": ["工作区域实际状态", "本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "裂纹萌生/陶瓷剥离观察说明", "试样居中及跨距确认"], "_change_reason": "", "_precheck_note": "", "report_summary": "BP20260817001-S01：结合强度576MPa；BP20260817001-S02：结合强度576MPa", "_overall_status": "正常完成", "_report_summary": "", "_template_fields": [{"key": "t0_r8_c1", "value": "☑委托要求 □产品技术要求 □内部质量要求 □其他：/"}, {"key": "t3_r1_c3", "value": "☑符合 □不符合"}, {"key": "t3_r2_c3", "value": "☑符合 □不符合"}, {"key": "t3_r3_c3", "value": "☑符合 □不符合"}, {"key": "t3_r4_c3", "value": "☑符合 □不符合"}, {"key": "t3_r5_c2", "value": "☑无毛刺 □无缺口 □无锈蚀 □无明显磨损"}, {"key": "t3_r5_c3", "value": "☑符合 □不符合"}, {"key": "t3_r6_c3", "value": "☑符合 □不符合"}, {"key": "t3_r7_c3", "value": "☑符合 □不符合"}, {"key": "t3_r8_c2", "value": "☑左右对称 ☑跨过两支撑 ☑未接触侧壁"}, {"key": "t3_r8_c3", "value": "☑符合 □不符合"}, {"key": "t3_r9_c2", "value": "☑夹具平行 ☑试样居中 ☑跨距符合"}, {"key": "t3_r9_c3", "value": "☑符合 □不符合"}, {"key": "t3_r10_c2", "value": "李红丽"}, {"key": "t4_r1_c1", "value": "试样名称：试样名称：金瓷结合强度试样；批号：123；批号：________________"}, {"key": "t4_r2_c1", "value": "EM = / GPa；来源：☑说明书 ☑检测报告 ☑注册资料 ☑质保书 ☑其他：/；文件编号：/"}, {"key": "t4_r4_c1", "value": "121"}, {"key": "t5_r1_c1", "value": "☑是 □否"}, {"key": "t5_r2_c1", "value": "☑是 □否"}, {"key": "t5_r3_c1", "value": "☑是 □否"}, {"key": "t5_r4_c1", "value": "☑试样居中 ☑夹具状态正常 ☑设备状态正常"}, {"key": "t5_r5_c1", "value": "/ mm/min；要求（1.5±0.5） mm/min；☑符合 □不符合"}, {"key": "t5_r6_c1", "value": "12"}, {"key": "t7_r3_c1", "value": "wu"}, {"key": "t7_r4_c1", "value": "☑FastTest原始数据 ☑Office报告 ☑断裂形态照片 ☑k系数查图记录 ☑其他：/"}, {"key": "t7_r9_c2", "value": "13"}], "_equipment_checks": [{"note": "", "model": "", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "辅助量具", "manufacturer": "", "management_no": "BPGL-A001", "equipment_name": "数显游标卡尺", "equipment_class": "A类", "measuring_range": "（0～150）mm", "calibration_time": ""}, {"note": "", "model": "YZ-0508", "status": "正常", "required": false, "serial_no": "", "responsible": "", "binding_role": "环境监测", "manufacturer": "扬子", "management_no": "BPGL-A009", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "STS50K", "status": "正常", "required": true, "serial_no": "20260323020", "responsible": "", "binding_role": "主设备", "manufacturer": "厦门易仕特仪器有限公司", "management_no": "BPGL-A021", "equipment_name": "电子万能试验机", "equipment_class": "A类", "measuring_range": "（0～50）kN，0.5级；（0～2000）N，0.5级", "calibration_time": ""}, {"note": "", "model": "", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "夹具", "manufacturer": "厦门易仕特仪器有限公司", "management_no": "BPGL-B009", "equipment_name": "金瓷结合试验夹具", "equipment_class": "B类", "measuring_range": "", "calibration_time": ""}, {"note": "", "model": "（30×6×5）mm", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "primary", "manufacturer": "", "management_no": "BPGL-B019", "equipment_name": "平行块", "equipment_class": "B类", "measuring_range": "", "calibration_time": ""}], "_fixed_param_mode": "按默认参数执行", "report_conclusion": "符合", "tester_self_check": true, "_report_conclusion": "", "_tester_self_check": true, "_precheck_all_items": ["工作区域实际状态", "本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "试样居中及跨距确认", "裂纹萌生/陶瓷剥离观察说明"], "_task_confirm_photo": "/api/v1/attachments/file/BP20260817001-T01/BP20260817001-T01_152232_2.jpg", "_task_confirmations": {"number_match": true, "sample_received": true, "sample_condition": true}, "_standard_block_measured": null}	A/0	A/0		2026-08-17 15:22:32.701667+08	2026-08-17 15:32:39.781916+08	\N	2026-08-17 15:11:28.591521+08	2026-08-17 16:21:47.287692+08
6	BP20260819005-T01	BP20260819005-T01	1	金属内部质量X射线灰度分析	liuhong_test	草稿	{"_form": {"mas": 1, "iqi_no": "BPGL-B016;BPGL-B017;BPGL-B018", "end_time": "", "panel_no": "BPGL-B024", "software": "", "data_path": "", "test_date": "2026-08-19", "focus_mode": "S", "image_path": "", "start_time": "2026-08-19 11:01:59", "xray_model": "BPGL-A032", "orientation": "咬合面朝下", "equipment_no": "", "tube_current": 14, "tube_voltage": 72, "exposure_time": 71, "iqi_gray_01_1": 0, "iqi_gray_01_2": 0, "iqi_gray_01_3": 0, "iqi_gray_02_1": 0, "iqi_gray_02_2": 0, "iqi_gray_02_3": 0, "iqi_gray_03_1": 0, "iqi_gray_03_2": 0, "iqi_gray_03_3": 0, "iqi_gray_04_1": 0, "iqi_gray_04_2": 0, "iqi_gray_04_3": 0, "iqi_gray_05_1": 0, "iqi_gray_05_2": 0, "iqi_gray_05_3": 0, "iqi_gray_06_1": 0, "iqi_gray_06_2": 0, "iqi_gray_06_3": 0, "iqi_gray_07_1": 0, "iqi_gray_07_2": 0, "iqi_gray_07_3": 0, "iqi_gray_08_1": 0, "iqi_gray_08_2": 0, "iqi_gray_08_3": 0, "iqi_gray_09_1": 0, "iqi_gray_09_2": 0, "iqi_gray_09_3": 0, "iqi_gray_10_1": 0, "iqi_gray_10_2": 0, "iqi_gray_10_3": 0, "equipment_name": "", "exposure_count": 1, "calibration_due": "", "density_nominal": 2, "equipment_model": "", "humidity_before": 50, "density_meter_no": "BPGL-A029;BPGL-B005", "equipment_status": "", "radiation_safety": "允许曝光", "work_area_status": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "temperature_after": 23, "density_measured_1": 2, "density_measured_2": 2, "density_measured_3": 2, "detection_location": "无损检测室", "temperature_before": 23, "humidity_compliance": "符合", "sample_surface_xray": "符合", "work_area_condition": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "density_control_note": "核查结果在受控范围内", "parameter_adjustment": "无调整", "radiation_zone_clear": "符合", "operator_authorization": "已授权", "sample_production_date": "444", "temperature_compliance": "符合", "calibration_certificate": "", "interference_compliance": "符合", "environment_interference": "无明显干扰", "sample_preparation_actual": "已按方法要求确认", "method_execution_confirmation": "一致", "panel_iqi_position_confirmation": "符合", "equipment_traceability_confirmation": "已核对且在有效期内"}, "_rows": [{"note": "", "roi1": 1.21, "roi2": 0.0, "roi3": 0.0, "defect": "", "retake": "否", "image_no": "", "roi_mean": 0.4, "_showNote": false, "sample_no": "BP20260819005-S01", "conclusion": "合格", "image_valid": "有效", "iqi_display": "清晰", "roi1_reading1": 1.08, "roi1_reading2": 1.31, "roi1_reading3": 1.24, "roi2_reading1": 0, "roi2_reading2": 0, "roi2_reading3": 0, "roi3_reading1": 0, "roi3_reading2": 0, "roi3_reading3": 0, "sample_status": "完好", "sample_name_tooth": "", "thickness_relation": "", "estimated_thickness": ""}], "_photos": [], "_retest": "否", "_deviation": "", "_prechecks": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "样品表面清洁、干燥状态", "辐射区域无无关人员及物品", "探测板、像质计与样品位置确认", "X射线操作授权确认", "密度/灰度标准控制范围及核查说明"], "_change_reason": "", "_precheck_note": "", "report_summary": "BP20260819005-S01：ROI平均灰度0.4", "_overall_status": "正常完成", "_report_summary": "", "_template_fields": [{"key": "t0_r0_c3", "value": ""}, {"key": "t1_r4_c1", "value": ""}, {"key": "t1_r4_c3", "value": ""}, {"key": "t1_r7_c1", "value": ""}, {"key": "t2_r0_c3", "value": "____:____"}, {"key": "t2_r3_c1", "value": ""}, {"key": "t2_r3_c3", "value": ""}, {"key": "t2_r3_c5", "value": ""}, {"key": "t2_r4_c1", "value": ""}, {"key": "t2_r4_c3", "value": ""}, {"key": "t2_r4_c5", "value": ""}, {"key": "t2_r5_c1", "value": ""}, {"key": "t2_r5_c3", "value": ""}, {"key": "t2_r5_c5", "value": ""}, {"key": "t3_r6_c1", "value": ""}, {"key": "t5_r0_c5", "value": ""}, {"key": "t5_r1_c5", "value": ""}, {"key": "t5_r2_c5", "value": ""}, {"key": "t5_r3_c3", "value": ""}, {"key": "t5_r3_c5", "value": ""}, {"key": "t5_r4_c5", "value": ""}, {"key": "t5_r5_c5", "value": ""}, {"key": "t5_r6_c1", "value": ""}, {"key": "t7_r2_c2", "value": ""}, {"key": "t7_r2_c10", "value": ""}, {"key": "t7_r3_c2", "value": ""}, {"key": "t8_r1_c2", "value": "ROI-1：ROI-1：0； ROI-2：0； ROI-3：0； ROI-2：____； ROI-3：____"}, {"key": "t8_r1_c3", "value": "□接近____mm □介于____～____mm"}, {"key": "t8_r1_c4", "value": "约____mm/____～____mm"}, {"key": "t9_r1_c1", "value": ""}, {"key": "t9_r2_c1", "value": ""}, {"key": "t9_r3_c1", "value": ""}, {"key": "t9_r4_c1", "value": ""}, {"key": "t9_r5_c1", "value": ""}, {"key": "t9_r6_c1", "value": ""}, {"key": "t9_r7_c1", "value": ""}, {"key": "t9_r8_c1", "value": ""}, {"key": "t9_r9_c1", "value": ""}, {"key": "t9_r9_c2", "value": ""}, {"key": "t9_r10_c1", "value": ""}, {"key": "t9_r10_c2", "value": ""}, {"key": "t9_r11_c1", "value": ""}, {"key": "t9_r11_c2", "value": ""}, {"key": "t9_r12_c1", "value": ""}, {"key": "t9_r12_c2", "value": ""}, {"key": "t9_r13_c1", "value": ""}, {"key": "t9_r13_c2", "value": ""}, {"key": "t10_r0_c1", "value": ""}, {"key": "t10_r0_c3", "value": ""}, {"key": "t10_r1_c1", "value": ""}, {"key": "t10_r1_c3", "value": ""}, {"key": "t10_r2_c1", "value": ""}, {"key": "t10_r3_c3", "value": ""}], "_equipment_checks": [{"note": "", "model": "DryView5700C/6950", "status": "正常", "required": true, "serial_no": "69135596", "responsible": "", "binding_role": "成像设备", "manufacturer": "锐珂（上海）医疗器材有限公司", "management_no": "BPGL-A033", "equipment_name": "干式激光成像仪", "equipment_class": "A类", "measuring_range": "/", "calibration_time": ""}, {"note": "", "model": "DV-9A", "status": "正常", "required": true, "serial_no": "265083", "responsible": "", "binding_role": "标准器", "manufacturer": "济宁科锐检测仪器有限公司", "management_no": "BPGL-B005", "equipment_name": "密度片", "equipment_class": "B类", "measuring_range": "0.00～5.00 D", "calibration_time": ""}, {"note": "", "model": "YZ-0508", "status": "正常", "required": false, "serial_no": "", "responsible": "", "binding_role": "环境监测", "manufacturer": "扬子", "management_no": "BPGL-A011", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "KM-500", "status": "正常", "required": true, "serial_no": "124506", "responsible": "", "binding_role": "测量设备", "manufacturer": "济宁科锐检测仪器有限公司", "management_no": "BPGL-A029", "equipment_name": "黑白密度计", "equipment_class": "A类", "measuring_range": "0.00～5.00 D", "calibration_time": ""}, {"note": "", "model": "R103", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "主设备", "manufacturer": "丹东市科大仪器有限公司", "management_no": "BPGL-A032", "equipment_name": "医用X射线限束器", "equipment_class": "A类", "measuring_range": "X射线泄漏：<0.5 mGy/h（120 kV、4 mA）", "calibration_time": ""}, {"note": "", "model": "", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "primary", "manufacturer": "", "management_no": "BPGL-B024", "equipment_name": "数位采集板", "equipment_class": "B类", "measuring_range": "", "calibration_time": ""}, {"note": "", "model": "纯钛", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "primary", "manufacturer": "", "management_no": "BPGL-B018", "equipment_name": "孔型像质计", "equipment_class": "B类", "measuring_range": "", "calibration_time": ""}, {"note": "", "model": "钛合金", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "primary", "manufacturer": "", "management_no": "BPGL-B017", "equipment_name": "孔型像质计", "equipment_class": "B类", "measuring_range": "", "calibration_time": ""}, {"note": "", "model": "钴铬合金", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "primary", "manufacturer": "", "management_no": "BPGL-B016", "equipment_name": "孔型像质计", "equipment_class": "B类", "measuring_range": "", "calibration_time": ""}], "_fixed_param_mode": "按默认参数执行", "report_conclusion": "符合", "tester_self_check": false, "_report_conclusion": "", "_tester_self_check": false, "_precheck_all_items": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "样品表面清洁、干燥状态", "辐射区域无无关人员及物品", "探测板、像质计与样品位置确认", "X射线操作授权确认", "密度/灰度标准控制范围及核查说明"], "_task_confirm_photo": "", "_task_confirmations": {"number_match": true, "sample_received": true, "sample_condition": true}, "_standard_block_measured": null}	A/0	A/0		\N	\N	\N	2026-08-19 11:02:29.581384+08	2026-08-19 11:31:50.504791+08
7	BP20260819006-T01	BP20260819006-T01	1	表面粗糙度试验	liuhong_test	草稿	{"_form": {"end_time": "", "lambda_s": "自动", "software": "", "data_path": "", "test_date": "2026-08-19", "start_time": "2026-08-19 11:51:18", "filter_type": "高斯", "equipment_no": "", "cutoff_filter": "高斯", "shape_removal": "自动", "surface_state": "", "equipment_name": "", "platform_level": "符合", "repeat_check_1": 0, "repeat_check_3": 0, "sampling_count": 3, "standard_block": "BPGL-B001", "z_axis_marking": "清晰", "calibration_due": "", "equipment_model": "", "humidity_before": 50, "measuring_speed": 1, "sampling_length": 2.5, "equipment_status": "", "work_area_status": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "evaluation_length": 7.5, "fixture_stability": "符合", "measurement_range": 40, "temperature_after": 23, "three_length_mode": "3L（默认）", "detection_location": "性能检测室", "temperature_before": 23, "work_area_condition": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "calculation_standard": "ISO-97", "measurement_direction": "3条平行、不重叠、代表性测量线", "measurement_line_note": "按受控方法规定位置测量", "standard_block_result": "", "sample_production_date": "12", "standard_block_nominal": 1.61, "calibration_certificate": "", "interference_compliance": "符合", "surface_cleaning_actual": "清洁", "environment_interference": "无明显干扰", "sample_preparation_actual": "已按方法要求确认", "method_execution_confirmation": "一致", "equipment_traceability_confirmation": "已核对且在有效期内"}, "_rows": [{"ra1": 0, "ra2": 0, "ra3": 0, "mean": 0.0, "note": "", "limit": 15, "file_no": "", "position": "Z轴", "_showNote": false, "sample_no": "BP20260819006-S01", "conclusion": "符合", "retest_mean": 0, "surface_confirm": "符合"}], "_photos": [], "_retest": "否", "_deviation": "", "_prechecks": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "Z轴正方向标识", "测试面清洁状态", "试样固定及工作台稳定性", "实际测量线/方向说明"], "_change_reason": "", "_precheck_note": "", "report_summary": "BP20260819006-S01：平均Ra0μm", "_overall_status": "正常完成", "_report_summary": "", "_template_fields": [{"key": "t0_r1_c4", "value": ""}, {"key": "t1_r6_c3", "value": ""}, {"key": "t2_r2_c3", "value": "____ %RH"}, {"key": "t5_r2_c2", "value": ""}, {"key": "t5_r8_c1", "value": "□5 □3（需特别说明）"}, {"key": "t6_r0_c1", "value": ""}, {"key": "t6_r0_c3", "value": ""}, {"key": "t6_r1_c3", "value": ""}, {"key": "t6_r2_c1", "value": ""}, {"key": "t6_r2_c3", "value": ""}, {"key": "t6_r3_c1", "value": ""}, {"key": "t6_r3_c3", "value": ""}, {"key": "t6_r4_c1", "value": ""}, {"key": "t6_r4_c3", "value": ""}, {"key": "t6_r5_c1", "value": ""}, {"key": "t6_r5_c3", "value": ""}, {"key": "t7_r1_c6", "value": "□平行纹理 □垂直纹理 □其他"}, {"key": "t8_r1_c1", "value": "最小值：0 μm；最大值：____ μm"}, {"key": "t10_r1_c2", "value": "刘红"}, {"key": "t10_r2_c2", "value": ""}, {"key": "t10_r3_c2", "value": ""}, {"key": "t10_r4_c2", "value": ""}, {"key": "t10_r5_c2", "value": ""}, {"key": "t10_r6_c2", "value": ""}, {"key": "t10_r7_c2", "value": "李红丽"}, {"key": "t11_r1_c2", "value": ""}, {"key": "t11_r2_c2", "value": ""}, {"key": "t11_r3_c2", "value": ""}, {"key": "t11_r4_c2", "value": ""}, {"key": "t11_r5_c2", "value": ""}, {"key": "t11_r6_c2", "value": ""}, {"key": "t11_r7_c2", "value": ""}, {"key": "t12_r3_c2", "value": ""}], "_equipment_checks": [{"note": "", "model": "TR200", "status": "正常", "required": true, "serial_no": "SR260117E013", "responsible": "", "binding_role": "主设备", "manufacturer": "掘扬精密量仪有限公司", "management_no": "BPGL-A036", "equipment_name": "粗糙度仪", "equipment_class": "A类", "measuring_range": "±160 μm", "calibration_time": ""}, {"note": "", "model": "", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "标准器", "manufacturer": "掘扬精密量仪有限公司", "management_no": "BPGL-B001", "equipment_name": "粗糙度标准块", "equipment_class": "B类", "measuring_range": "Ra 1.61 μm", "calibration_time": ""}, {"note": "", "model": "YZ-0508", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "环境监测", "manufacturer": "扬子", "management_no": "BPGL-A009", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "测量平台", "manufacturer": "山光", "management_no": "BPGL-A040", "equipment_name": "大理石平台", "equipment_class": "A类", "measuring_range": "（300×200）mm，00级", "calibration_time": ""}, {"note": "", "model": "Dasqua", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "水平确认", "manufacturer": "", "management_no": "BPGL-A041", "equipment_name": "高精度数字水平仪", "equipment_class": "A类", "measuring_range": "±0.01 mm/m", "calibration_time": ""}], "_fixed_param_mode": "按默认参数执行", "report_conclusion": "符合", "tester_self_check": false, "_report_conclusion": "", "_tester_self_check": false, "_precheck_all_items": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "Z轴正方向标识", "测试面清洁状态", "试样固定及工作台稳定性", "实际测量线/方向说明"], "_task_confirm_photo": "", "_task_confirmations": {"number_match": true, "sample_received": true, "sample_condition": true}, "_standard_block_measured": null}	A/0	A/0		\N	\N	\N	2026-08-19 11:51:23.295567+08	2026-08-19 11:51:45.275264+08
3	BP20260818001-T02	BP20260818001-T02	1	维氏硬度试验	liuhong_test	草稿	{"_form": {"method": "HV10", "end_time": "", "software": "", "data_path": "", "test_date": "2026-08-18", "dwell_time": 15, "start_time": "2026-08-18 14:38:18", "test_force": 98.07, "equipment_no": "", "equipment_name": "", "humidity_after": 50, "calibration_due": "", "equipment_model": "", "humidity_before": 50, "report_exported": "是", "equipment_status": "", "perpendicularity": "", "work_area_status": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "standard_block_no": "BPGL-B007", "surface_condition": "", "temperature_after": 23, "detection_location": "性能检测室", "standard_block_due": "2026-08-18", "temperature_before": 23, "humidity_compliance": "符合", "work_area_condition": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "standard_block_result": "", "sample_production_date": "123", "standard_block_nominal": 466, "surface_preparation_hv": "表面平整清洁且不影响压痕", "temperature_compliance": "符合", "calibration_certificate": "", "interference_compliance": "符合", "software_version_actual": "由设备配置核对", "environment_interference": "无明显干扰", "standard_block_reading_1": 0, "standard_block_reading_2": 0, "standard_block_reading_3": 0, "indent_measurement_method": "切线测量", "sample_preparation_actual": "已按方法要求确认", "method_execution_confirmation": "一致", "loading_unloading_confirmation": "正常", "equipment_traceability_confirmation": "已核对且在有效期内"}, "_rows": [{"face": "Z轴方向", "mean": 0.0, "note": "", "indent1": 0, "indent2": 0, "indent3": 0, "image_no": "", "_showNote": false, "sample_no": "BP20260818001-S01", "indent_quality": "有效"}, {"face": "X轴方向", "mean": 0.0, "note": "", "indent1": 0, "indent2": 0, "indent3": 0, "image_no": "", "_showNote": false, "sample_no": "BP20260818001-S01", "indent_quality": "有效"}, {"face": "Z轴方向", "mean": 0.0, "note": "", "indent1": 0, "indent2": 0, "indent3": 0, "image_no": "", "_showNote": false, "sample_no": "BP20260818001-S02", "indent_quality": "有效"}, {"face": "X轴方向", "mean": 0.0, "note": "", "indent1": 0, "indent2": 0, "indent3": 0, "image_no": "", "_showNote": false, "sample_no": "BP20260818001-S02", "indent_quality": "有效"}], "_photos": [], "_retest": "否", "_deviation": "", "_prechecks": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "测试面磨制/抛光及清洁状态", "本次硬度测量软件版本", "加载、保荷及卸载过程"], "_change_reason": "", "_precheck_note": "", "report_summary": "BP20260818001-S01-Z轴方向：平均维氏硬度0HV10；BP20260818001-S01-X轴方向：平均维氏硬度0HV10；BP20260818001-S02-Z轴方向：平均维氏硬度0HV10；BP20260818001-S02-X轴方向：平均维氏硬度0HV10", "_overall_status": "正常完成", "_report_summary": "", "_template_fields": [{"key": "t0_r6_c3", "value": ""}, {"key": "t0_r7_c3", "value": ""}, {"key": "t0_r7_c5", "value": ""}, {"key": "t2_r0_c1", "value": ""}, {"key": "t2_r0_c3", "value": ""}, {"key": "t2_r3_c5", "value": "□合格 □不合格"}, {"key": "t2_r4_c3", "value": ""}, {"key": "t2_r5_c1", "value": "□平整 □清洁 □无油污 □无氧化皮 □无影响压痕缺陷"}, {"key": "t2_r5_c3", "value": ""}, {"key": "t2_r5_c5", "value": "□平稳 □测试面与压头轴线垂直"}, {"key": "t3_r0_c7", "value": ""}, {"key": "t4_r1_c1", "value": ""}, {"key": "t4_r2_c1", "value": ""}, {"key": "t4_r3_c1", "value": ""}, {"key": "t4_r4_c1", "value": ""}, {"key": "t6_r3_c4", "value": ""}, {"key": "t6_r4_c4", "value": ""}, {"key": "t6_r5_c4", "value": ""}, {"key": "t6_r6_c4", "value": ""}, {"key": "t7_r1_c4", "value": ""}, {"key": "t7_r2_c4", "value": ""}, {"key": "t7_r3_c4", "value": ""}, {"key": "t7_r4_c4", "value": ""}, {"key": "t8_r1_c3", "value": ""}, {"key": "t8_r2_c3", "value": ""}, {"key": "t8_r3_c3", "value": ""}, {"key": "t8_r4_c3", "value": ""}, {"key": "t8_r5_c3", "value": ""}, {"key": "t8_r6_c3", "value": ""}, {"key": "t8_r7_c3", "value": ""}, {"key": "t8_r10_c4", "value": ""}], "_equipment_checks": [{"note": "", "model": "HV-30Z", "status": "正常", "required": true, "serial_no": "14053", "responsible": "", "binding_role": "主设备", "manufacturer": "上海尚材试验机有限公司", "management_no": "BPGL-A035", "equipment_name": "数显维氏硬度计", "equipment_class": "A类", "measuring_range": "HV10", "calibration_time": ""}, {"note": "", "model": "TR200", "status": "正常", "required": false, "serial_no": "SR260117E013", "responsible": "", "binding_role": "表面确认", "manufacturer": "掘扬精密量仪有限公司", "management_no": "BPGL-A036", "equipment_name": "粗糙度仪", "equipment_class": "A类", "measuring_range": "±160 μm", "calibration_time": ""}, {"note": "", "model": "况氏", "status": "正常", "required": true, "serial_no": "V261-176", "responsible": "", "binding_role": "标准器", "manufacturer": "南昌况氏", "management_no": "BPGL-B007", "equipment_name": "标准维氏硬度块", "equipment_class": "B类", "measuring_range": "466HV10", "calibration_time": ""}, {"note": "", "model": "YZ-0508", "status": "正常", "required": false, "serial_no": "", "responsible": "", "binding_role": "环境监测", "manufacturer": "扬子", "management_no": "BPGL-A009", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "YZ-0508", "status": "正常", "required": false, "serial_no": "", "responsible": "", "binding_role": "环境监测", "manufacturer": "扬子", "management_no": "BPGL-A010", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "YZ-0508", "status": "正常", "required": false, "serial_no": "", "responsible": "", "binding_role": "环境监测", "manufacturer": "扬子", "management_no": "BPGL-A011", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "/", "status": "正常", "required": false, "serial_no": "/", "responsible": "", "binding_role": "环境监测", "manufacturer": "蓝骏", "management_no": "BPGL-A012", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "/", "status": "正常", "required": false, "serial_no": "/", "responsible": "", "binding_role": "环境监测", "manufacturer": "蓝骏", "management_no": "BPGL-A013", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "/", "status": "正常", "required": false, "serial_no": "/", "responsible": "", "binding_role": "环境监测", "manufacturer": "蓝骏", "management_no": "BPGL-A014", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "/", "status": "正常", "required": false, "serial_no": "/", "responsible": "", "binding_role": "环境监测", "manufacturer": "蓝骏", "management_no": "BPGL-A015", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "/", "status": "正常", "required": false, "serial_no": "/", "responsible": "", "binding_role": "环境监测", "manufacturer": "蓝骏", "management_no": "BPGL-A016", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "P-2T", "status": "正常", "required": false, "serial_no": "03127", "responsible": "", "binding_role": "制样设备", "manufacturer": "莱州市蔚仪试验器械制造有限公司", "management_no": "BPGL-A019", "equipment_name": "金相试样抛光机", "equipment_class": "A类", "measuring_range": "/", "calibration_time": ""}], "_fixed_param_mode": "按默认参数执行", "report_conclusion": "仅描述结果", "tester_self_check": false, "_report_conclusion": "", "_tester_self_check": false, "_precheck_all_items": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "测试面磨制/抛光及清洁状态", "本次硬度测量软件版本", "加载、保荷及卸载过程"], "_task_confirm_photo": "", "_task_confirmations": {"number_match": true, "sample_received": true, "sample_condition": true}, "_standard_block_measured": 0}	A/0	A/0		\N	\N	\N	2026-08-18 15:19:53.321302+08	2026-08-18 15:30:39.990855+08
2	BP20260818001-T01	BP20260818001-T01	1	表面粗糙度试验	liuhong_test	草稿	{"_form": {"end_time": "", "lambda_s": "自动", "software": "", "data_path": "", "test_date": "2026-08-18", "start_time": "2026-08-18 14:38:18", "filter_type": "高斯", "equipment_no": "", "cutoff_filter": "高斯", "shape_removal": "自动", "surface_state": "", "equipment_name": "", "platform_level": "", "repeat_check_1": 0, "repeat_check_3": 0, "sampling_count": 5, "standard_block": "BPGL-B001", "z_axis_marking": "清晰", "calibration_due": "", "equipment_model": "", "humidity_before": null, "measuring_speed": 1, "sampling_length": 0.8, "equipment_status": "", "work_area_status": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "evaluation_length": 7.5, "fixture_stability": "符合", "measurement_range": 40, "temperature_after": 23, "three_length_mode": "5L（默认）", "detection_location": "性能检测室", "temperature_before": "符合", "work_area_condition": ["清洁", "干燥", "无明显粉尘", "无无关物品"], "calculation_standard": "ISO-97", "measurement_direction": "3条平行、不重叠、代表性测量线", "measurement_line_note": "按受控方法规定位置测量", "standard_block_result": "", "sample_production_date": "123", "standard_block_nominal": 3, "calibration_certificate": "", "interference_compliance": "符合", "surface_cleaning_actual": "清洁", "environment_interference": "无明显干扰", "sample_preparation_actual": "已按方法要求确认", "method_execution_confirmation": "一致", "equipment_traceability_confirmation": "已核对且在有效期内"}, "_rows": [{"ra1": 0, "ra2": 0, "ra3": 0, "mean": 0.0, "note": "", "limit": 15, "file_no": "", "position": "Z轴", "_showNote": false, "sample_no": "BP20260818001-S01", "conclusion": "符合", "retest_mean": 0, "surface_confirm": "符合"}, {"ra1": 0, "ra2": 0, "ra3": 0, "mean": 0.0, "note": "", "limit": 15, "file_no": "", "position": "Z轴", "_showNote": false, "sample_no": "BP20260818001-S02", "conclusion": "符合", "retest_mean": 0, "surface_confirm": "符合"}], "_photos": [], "_retest": "否", "_deviation": "", "_prechecks": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "Z轴正方向标识", "测试面清洁状态", "试样固定及工作台稳定性", "实际测量线/方向说明"], "_change_reason": "", "_precheck_note": "", "report_summary": "BP20260818001-S01：平均Ra0μm；BP20260818001-S02：平均Ra0μm", "_overall_status": "正常完成", "_report_summary": "", "_template_fields": [], "_equipment_checks": [{"note": "", "model": "TR200", "status": "正常", "required": true, "serial_no": "SR260117E013", "responsible": "", "binding_role": "主设备", "manufacturer": "掘扬精密量仪有限公司", "management_no": "BPGL-A036", "equipment_name": "粗糙度仪", "equipment_class": "A类", "measuring_range": "±160 μm", "calibration_time": ""}, {"note": "", "model": "", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "标准器", "manufacturer": "掘扬精密量仪有限公司", "management_no": "BPGL-B001", "equipment_name": "粗糙度标准块", "equipment_class": "B类", "measuring_range": "Ra 1.61 μm", "calibration_time": ""}, {"note": "", "model": "YZ-0508", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "环境监测", "manufacturer": "扬子", "management_no": "BPGL-A009", "equipment_name": "温湿度计", "equipment_class": "A类", "measuring_range": "温度：（-10～60）℃；相对湿度：（0～100）%", "calibration_time": ""}, {"note": "", "model": "", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "测量平台", "manufacturer": "山光", "management_no": "BPGL-A040", "equipment_name": "大理石平台", "equipment_class": "A类", "measuring_range": "（300×200）mm，00级", "calibration_time": ""}, {"note": "", "model": "Dasqua", "status": "正常", "required": true, "serial_no": "", "responsible": "", "binding_role": "水平确认", "manufacturer": "", "management_no": "BPGL-A041", "equipment_name": "高精度数字水平仪", "equipment_class": "A类", "measuring_range": "±0.01 mm/m", "calibration_time": ""}], "_fixed_param_mode": "按默认参数执行", "report_conclusion": "符合", "tester_self_check": false, "_report_conclusion": "", "_tester_self_check": false, "_precheck_all_items": ["本次温度条件是否符合", "本次湿度条件是否符合", "环境干扰控制是否符合", "工作区域实际状态", "设备证书、有效期及溯源信息核对结果", "样品生产日期/批次日期", "本次样品制备及表面状态说明", "本次操作与受控方法一致性", "Z轴正方向标识", "测试面清洁状态", "试样固定及工作台稳定性", "实际测量线/方向说明"], "_task_confirm_photo": "", "_task_confirmations": {"number_match": true, "sample_received": true, "sample_condition": true}, "_standard_block_measured": null}	A/0	A/0		\N	\N	\N	2026-08-18 14:38:36.246962+08	2026-08-19 10:32:12.866806+08
\.


--
-- Data for Name: report_actions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.report_actions (id, report_no, actor, action, comment, created_at) FROM stdin;
1	R20260817001-T01	system	自动生成报告初稿	原始记录复核通过后自动生成	2026-08-17 15:32:39.781916+08
2	R20260817001-T01	system	自动生成报告初稿	原始记录复核通过后自动生成	2026-08-17 15:32:39.781916+08
3	R20260817001-T01	quality	质量审核通过	质量审核通过	2026-08-17 15:37:08.727556+08
4	R20260817001-T01	admin	批准签发	批准签发	2026-08-17 15:37:34.923211+08
\.


--
-- Data for Name: report_deliveries; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.report_deliveries (id, report_no, client_name, delivery_method, recipient, recipient_contact, delivered_at, receipt_status, receipt_note, created_at) FROM stdin;
\.


--
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reports (report_no, commission_no, task_no, status, tester, verifier, quality_inspector, approver, source_versions, validity_status, supersedes_report_no, report_category, sample_statement, conclusion, notes, signed_by_tester, signed_by_verifier, signed_by_quality, signed_by_approver, publish_date, created_at, updated_at, archived_at, approver_signature) FROM stdin;
R20260817001-T01	WT20260817001	BP20260817001-T01	已发布	liuhong_test	lihongli_review	quality	admin	{"BP20260817001-T01": 1, "record_template": "A/0", "sop": "A/0"}	有效	\N	委托检验		符合	BP20260817001-S01：结合强度576MPa；BP20260817001-S02：结合强度576MPa	\N	\N	\N	2026-08-17 15:37:34.923211+08	2026-08-17	2026-08-17 15:32:39.781916+08	2026-08-17 15:37:34.923211+08	\N	admin
\.


--
-- Data for Name: requested_tests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.requested_tests (id, group_id, experiment_code, experiment, method_code, standard, status, task_no) FROM stdin;
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reviews (id, record_no, version, reviewer, decision, comment, correction_fields, reviewed_at) FROM stdin;
1	BP20260817001-T01	1	lihongli_review	通过		[]	2026-08-17 15:32:39.781916+08
\.


--
-- Data for Name: sample_catalog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sample_catalog (id, sample_code, sample_name, model, material_name, process, material_suffix, source_sequence, category, unit, experiment_codes, notes, enabled, created_at, updated_at, detection_method, detection_basis) FROM stdin;
2	SL002	牙科用纯钛	标准	纯钛	\N	\N	\N	\N	件	["I001", "I004", "I005", "I007", "I008", "I009"]	\N	t	2026-08-12 13:11:13.162483+08	2026-08-12 13:11:13.162483+08	\N	\N
3	SL003	牙科用钛合金	标准	钛合金	\N	\N	\N	\N	件	["I001", "I002", "I004", "I005", "I007", "I008", "I009"]	\N	t	2026-08-12 13:11:13.162483+08	2026-08-12 13:11:13.162483+08	\N	\N
4	SL004	牙科用镍铬合金	标准	镍铬合金	\N	\N	\N	\N	件	["I001", "I002", "I003", "I004", "I005", "I006", "I007", "I008", "I009"]	\N	t	2026-08-12 13:11:13.162483+08	2026-08-12 13:11:13.162483+08	\N	\N
5	SL005	牙科用氧化锆陶瓷	标准	氧化锆陶瓷	\N	\N	\N	\N	件	["I001", "I002", "I006", "I007", "I008", "I010"]	\N	t	2026-08-12 13:11:13.162483+08	2026-08-12 13:11:13.162483+08	\N	\N
6	SL006	牙科用烤瓷粉	标准	烤瓷粉	\N	\N	\N	\N	件	["I006", "I010"]	\N	t	2026-08-12 13:11:13.162483+08	2026-08-12 13:11:13.162483+08	\N	\N
7	SL007	牙科用PMMA树脂	标准	聚甲基丙烯酸甲酯	\N	\N	\N	\N	件	["I010"]	\N	t	2026-08-12 13:11:13.162483+08	2026-08-12 13:11:13.162483+08	\N	\N
8	SL008	牙科用金合金	标准	金合金	\N	\N	\N	\N	件	["I001", "I002", "I004", "I005", "I007", "I008", "I009", "I014"]	\N	t	2026-08-12 13:11:13.162483+08	2026-08-12 13:11:13.162483+08	\N	\N
9	SL009	增材制造用钴铬钼合金	标准	钴铬钼合金	\N	\N	\N	\N	件	["I001", "I004", "I005", "I007", "I008", "I009", "I013"]	\N	t	2026-08-12 13:11:13.162483+08	2026-08-12 13:11:13.162483+08	\N	\N
10	SL010	牙科用银钯合金	标准	银钯合金	\N	\N	\N	\N	件	["I001", "I004", "I005", "I007", "I008", "I009", "I014"]	\N	t	2026-08-12 13:11:13.162483+08	2026-08-12 13:11:13.162483+08	\N	\N
1	SL001	牙科用钴铬合金	标准	钴铬合金	\N	\N	\N	\N	件	["I001", "I002", "I003", "I004", "I005", "I006", "I007", "I008", "I009"]	\N	t	2026-08-12 13:11:13.162483+08	2026-08-17 16:22:43.299439+08	\N	\N
135	HD-GG-03	定制式活动义齿	钴铬合金铸造支架树脂基托全口义齿	钴铬合金	铸造	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
136	HD-GG-04	定制式活动义齿	钴铬合金激光熔融支架树脂基托可摘局部义齿	钴铬合金粉末	激光熔融	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
137	HD-GG-05	定制式活动义齿	钴铬合金切削支架树脂基托可摘局部义齿	钴铬合金	切削	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
138	HD-GG-06	定制式活动义齿	钴铬合金铸造支架树脂基托可摘局部义齿	钴铬合金	铸造	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
139	HD-SZ-01	定制式活动义齿	树脂基托全口义齿	树脂	树脂基托	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
140	HD-SZ-02	定制式活动义齿	树脂打印基托义齿	树脂	树脂打印	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
141	HD-SZ-03	定制式活动义齿	树脂切削基托全口义齿	树脂	切削	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
142	HD-SZ-04	定制式活动义齿	树脂基托可摘局部义齿	树脂	树脂基托	\N	\N	定制式活动义齿	件	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
143	HD-SZ-05	定制式活动义齿	弯制支架树脂基托可摘局部义齿	树脂	树脂基托	\N	\N	定制式活动义齿	件	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
144	HD-TH-01	定制式活动义齿	钛合金激光熔融支架树脂基托全口义齿	钛合金粉末	激光熔融	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
145	HD-TH-02	定制式活动义齿	钛合金激光熔融支架树脂基托可摘局部义齿	钛合金粉末	激光熔融	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
146	HD-TX-01	定制式活动义齿	弹性义齿材料树脂基托可摘局部义齿	弹性义齿材料	树脂基托	\N	\N	定制式活动义齿	件	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
147	SY-BM-08-1	表面粗糙度、硬度、密度、夹杂物和孔隙率试样	10mm×10mm×10mm	钴铬合金	激光熔融	1	\N	实验试样	件	["I001", "I008", "I013"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	表面粗糙度试验、维氏硬度试验、激光选区熔化金属材料密度试验	GB/T4340.1-2024《金属材料维氏硬度试验第1部分：试验方法》；YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；ISO22674:2022《牙科学固定和活动修复体和矫治器用金属材料》
148	SY-BM-08-2	表面粗糙度、硬度、密度、夹杂物和孔隙率试样	10mm×10mm×10mm	纯钛	激光熔融	2	\N	实验试样	件	["I001", "I008", "I013"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	表面粗糙度试验、维氏硬度试验、激光选区熔化金属材料密度试验	GB/T4340.1-2024《金属材料维氏硬度试验第1部分：试验方法》；YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；ISO22674:2022《牙科学固定和活动修复体和矫治器用金属材料》
149	SY-BM-08-3	表面粗糙度、硬度、密度、夹杂物和孔隙率试样	10mm×10mm×10mm	钛合金	激光熔融	3	\N	实验试样	件	["I001", "I008", "I013"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	表面粗糙度试验、维氏硬度试验、激光选区熔化金属材料密度试验	GB/T4340.1-2024《金属材料维氏硬度试验第1部分：试验方法》；YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；ISO22674:2022《牙科学固定和活动修复体和矫治器用金属材料》
150	SY-CC-01-1	尺寸、翘起变形试样	标准	钴铬合金	激光熔融	1	\N	实验试样	件	["I004", "I009"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	增材制造金属试样厚度测量、翘曲变形试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》
151	SY-CC-01-2	尺寸、翘起变形试样	标准	纯钛	激光熔融	2	\N	实验试样	件	["I004", "I009"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	增材制造金属试样厚度测量、翘曲变形试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》
95	GD-BL-01	定制式固定义齿	玻璃陶瓷切削全瓷桥（冠、嵌体、贴面）	玻璃陶瓷	切削	\N	\N	定制式固定义齿	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
96	GD-BL-02	定制式固定义齿	玻璃陶瓷切削烤瓷桥（冠）	玻璃陶瓷/饰面瓷	切削	\N	\N	定制式固定义齿	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
97	GD-CT-01	定制式固定义齿	纯钛激光熔融烤瓷桥（冠）	纯钛粉末/烤瓷粉	激光熔融	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
98	GD-CT-02	定制式固定义齿	纯钛激光熔融桥（冠、桩核、嵌体）	纯钛粉末	激光熔融	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
99	GD-CT-03	定制式固定义齿	纯钛铸造桥（冠）	纯钛	铸造	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
100	GD-CT-04	定制式固定义齿	纯钛切削桥（冠、嵌体）	纯钛	切削	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
101	GD-CT-05	定制式固定义齿	种植体上部纯钛切削桥（冠）	纯钛	切削	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
102	GD-CT-06	定制式固定义齿	纯钛切削光固化复合树脂桥（冠）	纯钛/复合树脂	切削；光固化复合	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
103	GD-CT-07	定制式固定义齿	纯钛铸造光固化复合树脂桥（冠）	纯钛/复合树脂	切削；光固化复合	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
104	GD-CT-08	定制式固定义齿	种植体上部纯钛切削光固化复合树脂桥（冠）	纯钛/复合树脂	种植体上部；切削；光固化复合	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
105	GD-CT-09	定制式固定义齿	纯钛切削烤瓷桥（冠）	齿科纯钛/烤瓷粉	切削	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
106	GD-CT-10	定制式固定义齿	纯钛铸造烤瓷桥（冠）	齿科纯钛/烤瓷粉	铸造	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
107	GD-FH-01	定制式固定义齿	复合树脂光固化（冠、贴面）	复合树脂	光固化	\N	\N	定制式固定义齿	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
108	GD-GG-01	定制式固定义齿	钴铬合金切削烤瓷桥（冠）	钴铬合金/烤瓷粉	切削	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
109	GD-GG-02	定制式固定义齿	钴铬合金激光熔融烤瓷桥（冠）	钴铬合金粉末/烤瓷粉	激光熔融	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
110	GD-GG-03	定制式固定义齿	钴铬合金铸造烤瓷桥（冠）	钴铬合金/烤瓷粉	铸造	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
111	GD-GG-04	定制式固定义齿	钴铬合金激光熔融桥（冠、桩核、嵌体）	钴铬合金粉末	激光熔融	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
112	GD-GG-05	定制式固定义齿	钴铬合金铸造桥（冠）	钴铬合金	铸造	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
113	GD-GG-06	定制式固定义齿	钴铬合金切削桥（冠）	钴铬合金	铸造	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
114	GD-JM-01	定制式固定义齿	聚醚醚酮切削光固化复合树脂桥（冠）	聚醚醚酮/复合树脂	切削；光固化复合	\N	\N	定制式固定义齿	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
115	GD-SZ-01	定制式固定义齿	临时冠桥树脂切削桥（冠）该产品非固定义齿类产品	临时冠桥树脂	切削	\N	\N	定制式固定义齿	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
116	QT-SZ-02	定制式固定义齿	光固化树脂打印冠（嵌体、贴面）	增材制造用光固化冠桥树脂	树脂打印	\N	\N	其他/待确认	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
117	GD-NG-01	定制式固定义齿	镍铬合金铸造烤瓷桥（冠）	镍铬合金/烤瓷粉	铸造	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
118	GD-NG-02	定制式固定义齿	镍铬合金铸造桥（冠）	镍铬合金	切削	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
119	GD-TH-01	定制式固定义齿	钛合金激光熔融烤瓷桥（冠）	钛合金粉末/烤瓷粉	激光熔融	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
120	GD-TH-02	定制式固定义齿	钛合金激光熔融桥（冠、桩核、嵌体）	钛合金粉末	激光熔融	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
121	GD-TH-03	定制式固定义齿	钛合金激光熔融光固化复合树脂桥（冠）	钛合金/复合树脂	激光熔融；光固化复合	\N	\N	定制式固定义齿	件	["I001", "I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
122	GD-YH-01	定制式固定义齿	氧化锆切削全瓷桥（冠、桩核、嵌体、贴面）	氧化锆	切削	\N	\N	定制式固定义齿	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
123	GD-YH-02	定制式固定义齿	种植体上部氧化锆切削全瓷桥（冠）	氧化锆	切削	\N	\N	定制式固定义齿	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
124	GD-YH-03	定制式固定义齿	氧化锆切削烤瓷桥（冠）	氧化锆/饰面瓷	切削	\N	\N	定制式固定义齿	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
125	GD-ZC-01	定制式固定义齿	铸瓷压铸全瓷桥（冠、嵌体、贴面）	铸瓷	压铸	\N	\N	定制式固定义齿	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
126	GD-ZC-02	定制式固定义齿	铸瓷压铸烤瓷桥（冠）	铸瓷/饰面瓷	压铸	\N	\N	定制式固定义齿	件	["I011"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式固定义齿检验	YY/T1936-2024《定制式固定义齿》
127	HD-CT-01	定制式活动义齿	纯钛切削支架树脂基托全口义齿	齿科纯钛	切削	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
128	HD-CT-02	定制式活动义齿	纯钛铸造支架树脂基托全口义齿	齿科纯钛	铸造	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
129	HD-CT-03	定制式活动义齿	纯钛切削支架树脂基托可摘局部义齿	齿科纯钛	切削	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
130	HD-CT-04	定制式活动义齿	纯钛铸造支架树脂基托可摘局部义齿	齿科纯钛	铸造	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
131	HD-CT-05	定制式活动义齿	纯钛激光熔融支架树脂基托全口义齿	纯钛粉末	激光熔融	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
132	HD-CT-06	定制式活动义齿	纯钛激光熔融支架树脂基托可摘局部义齿	纯钛粉末	激光熔融	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
133	HD-GG-01	定制式活动义齿	钴铬合金激光熔融支架树脂基托全口义齿	钴铬合金粉末	激光熔融	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
134	HD-GG-02	定制式活动义齿	钴铬合金切削支架树脂基托全口义齿	钴铬合金	切削	\N	\N	定制式活动义齿	副	["I012"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	定制式活动义齿检验	YY/T1937-2024《定制式活动义齿》
152	SY-CC-01-3	尺寸、翘起变形试样	标准	钛合金	激光熔融	3	\N	实验试样	件	["I004", "I009"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	增材制造金属试样厚度测量、翘曲变形试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》
153	SY-JC-10-1	金瓷结合性能试样	标准	钴铬合金	激光熔融	1	\N	实验试样	件	["I002"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	金属-陶瓷结合裂纹萌生试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；YY0621.1-2016《牙科学匹配性试验第1部分：金属-陶瓷体系》
154	SY-JC-10-2	金瓷结合性能试样	标准	纯钛	激光熔融	2	\N	实验试样	件	["I002"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	金属-陶瓷结合裂纹萌生试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；YY0621.1-2016《牙科学匹配性试验第1部分：金属-陶瓷体系》
155	SY-JC-10-3	金瓷结合性能试样	标准	钛合金	激光熔融	3	\N	实验试样	件	["I002"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	金属-陶瓷结合裂纹萌生试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；YY0621.1-2016《牙科学匹配性试验第1部分：金属-陶瓷体系》
156	SY-KH-03-1	抗晦暗（静态侵泡）试样	长20mm×宽15mm×厚1mm	钴铬合金	激光熔融	1	\N	实验试样	件	["I014"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	金属材料抗晦暗性能试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；ISO22674:2022《牙科学固定和活动修复体和矫治器用金属材料》；YY/T0528-2025《牙科金属材料-腐蚀试验方法》
157	SY-KH-03-2	抗晦暗（静态侵泡）试样	长20mm×宽15mm×厚1mm	纯钛	激光熔融	2	\N	实验试样	件	["I014"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	金属材料抗晦暗性能试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；ISO22674:2022《牙科学固定和活动修复体和矫治器用金属材料》；YY/T0528-2025《牙科金属材料-腐蚀试验方法》
158	SY-KH-03-3	抗晦暗（静态侵泡）试样	长20mm×宽15mm×厚1mm	钛合金	激光熔融	3	\N	实验试样	件	["I014"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	金属材料抗晦暗性能试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；ISO22674:2022《牙科学固定和活动修复体和矫治器用金属材料》；YY/T0528-2025《牙科金属材料-腐蚀试验方法》
159	SY-KH-04-1	抗晦暗（周期侵泡）试样	长20mm×宽15mm×厚1mm	钴铬合金	激光熔融	1	\N	实验试样	件	["I014"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	金属材料抗晦暗性能试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；ISO22674:2022《牙科学固定和活动修复体和矫治器用金属材料》；YY/T0528-2025《牙科金属材料-腐蚀试验方法》
160	SY-KH-04-2	抗晦暗（周期侵泡）试样	长20mm×宽15mm×厚1mm	纯钛	激光熔融	2	\N	实验试样	件	["I014"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	金属材料抗晦暗性能试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；ISO22674:2022《牙科学固定和活动修复体和矫治器用金属材料》；YY/T0528-2025《牙科金属材料-腐蚀试验方法》
161	SY-KH-04-3	抗晦暗（周期侵泡）试样	长20mm×宽15mm×厚1mm	钛合金	激光熔融	3	\N	实验试样	件	["I014"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	金属材料抗晦暗性能试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；ISO22674:2022《牙科学固定和活动修复体和矫治器用金属材料》；YY/T0528-2025《牙科金属材料-腐蚀试验方法》
162	SY-LS-05-1	拉伸性能试样	标准	钴铬合金	激光熔融	1	\N	实验试样	件	[]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	\N	\N
163	SY-LS-05-2	拉伸性能试样	标准	纯钛	激光熔融	2	\N	实验试样	件	[]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	\N	\N
164	SY-LS-05-3	拉伸性能试样	标准	钛合金	激光熔融	3	\N	实验试样	件	[]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	\N	\N
165	SY-NF-02-1	耐腐蚀性试样	34mm×13mm×1.5mm	钴铬合金	激光熔融	1	\N	实验试样	件	[]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	\N	\N
166	SY-NF-02-2	耐腐蚀性试样	34mm×13mm×1.5mm	纯钛	激光熔融	2	\N	实验试样	件	[]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	\N	\N
167	SY-NF-02-3	耐腐蚀性试样	34mm×13mm×1.5mm	钛合金	激光熔融	3	\N	实验试样	件	[]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	\N	\N
168	SY-TX-06-1	弹性模量试样	（31±1）mm×（11±1）mm×（1.2±0.2）mm	钴铬合金	激光熔融	1	\N	实验试样	件	[]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	\N	\N
169	SY-TX-06-2	弹性模量试样	（31±1）mm×（11±1）mm×（1.2±0.2）mm	纯钛	激光熔融	2	\N	实验试样	件	[]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	\N	\N
170	SY-TX-06-3	弹性模量试样	（31±1）mm×（11±1）mm×（1.2±0.2）mm	钛合金	激光熔融	3	\N	实验试样	件	[]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	\N	\N
171	SY-WQ-07-1	弯曲性能试样	（25±2）mm×（2±0.1）mm×（2±0.1）mm	钴铬合金	激光熔融	1	\N	实验试样	件	["I007"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	弯曲性能试样	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》
172	SY-WQ-07-2	弯曲性能试样	（25±2）mm×（2±0.1）mm×（2±0.1）mm	纯钛	激光熔融	2	\N	实验试样	件	["I007"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	弯曲性能试样	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》
173	SY-WQ-07-3	弯曲性能试样	（25±2）mm×（2±0.1）mm×（2±0.1）mm	钛合金	激光熔融	3	\N	实验试样	件	["I007"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	弯曲性能试样	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》
174	SY-XZ-09-1	线胀系数试样	直径5mm×长20mm	钴铬合金	激光熔融	1	\N	实验试样	件	["I005"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	热膨胀系数试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；GB17168-2013《牙科学固定和活动修复用金属材料》
175	SY-XZ-09-2	线胀系数试样	直径5mm×长20mm	纯钛	激光熔融	2	\N	实验试样	件	["I005"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	热膨胀系数试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；GB17168-2013《牙科学固定和活动修复用金属材料》
176	SY-XZ-09-3	线胀系数试样	直径5mm×长20mm	钛合金	激光熔融	3	\N	实验试样	件	["I005"]	\N	t	2026-08-18 16:22:00.508237+08	2026-08-18 16:22:00.508237+08	热膨胀系数试验	YY/T1702-2020《牙科学增材制造口腔固定和活动修复用激光选区熔化金属材料》；GB17168-2013《牙科学固定和活动修复用金属材料》
\.


--
-- Data for Name: sample_events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sample_events (id, sample_no, actor, action, from_status, to_status, from_location, to_location, details, created_at) FROM stdin;
\.


--
-- Data for Name: sample_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sample_groups (id, group_no, commission_no, catalog_id, sample_name, model, material_name, production_org_id, production_org_name, production_relation, product_no, production_date, quantity, unit, condition, condition_note, storage_area, notes, status, is_void, void_by, void_at, void_reason, created_at, updated_at, experiment_codes, batch_no) FROM stdin;
1	BP20260817001	WT20260817001	153	金瓷结合强度试样	标准	钴铬合金	\N	\N	\N	\N	\N	2	\N	\N	\N	\N	\N	已入库	f	\N	\N	\N	2026-08-17 15:07:43.827557+08	2026-08-17 15:07:43.827557+08	I002	123
2	BP20260818001	WT20260818001	147	表面粗糙度、硬度、密度、夹杂物和孔隙率试样	10mm×10mm×10mm	钴铬合金	\N	\N	\N	\N	\N	2	\N	\N	\N	\N	\N	已入库	f	\N	\N	\N	2026-08-18 14:36:13.218993+08	2026-08-18 14:36:13.218993+08	I001, I008, I013	123
3	BP20260819001	WT20260819001	153	金瓷结合性能试样	标准	钴铬合金	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	已入库	f	\N	\N	\N	2026-08-19 10:35:20.701094+08	2026-08-19 10:35:20.701094+08	I002	0231
4	BP20260819002	WT20260819002	135	定制式活动义齿	钴铬合金铸造支架树脂基托全口义齿	钴铬合金	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	已入库	f	\N	\N	\N	2026-08-19 10:53:16.511048+08	2026-08-19 10:53:16.511048+08	I012	11
5	BP20260819003	WT20260819003	135	定制式活动义齿	钴铬合金铸造支架树脂基托全口义齿	钴铬合金	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	已入库	f	\N	\N	\N	2026-08-19 10:57:27.518316+08	2026-08-19 10:57:27.518316+08	I012, I003	111
6	BP20260819004	WT20260819004	141	定制式活动义齿	树脂切削基托全口义齿	树脂	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	已入库	f	\N	\N	\N	2026-08-19 11:00:02.257423+08	2026-08-19 11:00:02.257423+08	I012	222
7	BP20260819005	WT20260819004	142	定制式活动义齿	树脂基托可摘局部义齿	树脂	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	已入库	f	\N	\N	\N	2026-08-19 11:00:02.266671+08	2026-08-19 11:00:02.266671+08	I003	444
8	BP20260819006	WT20260819005	1	牙科用钴铬合金	标准	钴铬合金	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	已入库	f	\N	\N	\N	2026-08-19 11:50:36.506391+08	2026-08-19 11:50:36.506391+08	I001	12
\.


--
-- Data for Name: samples; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.samples (sample_no, group_id, group_no, commission_no, sample_name, model, material_name, condition, condition_note, current_location, current_holder, status, created_at, updated_at, retention_period, retention_until, disposal_method, disposal_date, disposal_note, disposed_by) FROM stdin;
BP20260817001-S01	1	BP20260817001	WT20260817001	金瓷结合强度试样	标准	钴铬合金	待检	\N	样品库	\N	待检	2026-08-17 15:07:43.827557+08	2026-08-17 15:07:43.827557+08	\N	\N	\N	\N	\N	\N
BP20260817001-S02	1	BP20260817001	WT20260817001	金瓷结合强度试样	标准	钴铬合金	待检	\N	样品库	\N	待检	2026-08-17 15:07:43.827557+08	2026-08-17 15:07:43.827557+08	\N	\N	\N	\N	\N	\N
BP20260818001-S01	2	BP20260818001	WT20260818001	表面粗糙度、硬度、密度、夹杂物和孔隙率试样	10mm×10mm×10mm	钴铬合金	待检	\N	样品库	\N	待检	2026-08-18 14:36:13.218993+08	2026-08-18 14:36:13.218993+08	\N	\N	\N	\N	\N	\N
BP20260818001-S02	2	BP20260818001	WT20260818001	表面粗糙度、硬度、密度、夹杂物和孔隙率试样	10mm×10mm×10mm	钴铬合金	待检	\N	样品库	\N	待检	2026-08-18 14:36:13.218993+08	2026-08-18 14:36:13.218993+08	\N	\N	\N	\N	\N	\N
BP20260819001-S01	3	BP20260819001	WT20260819001	金瓷结合性能试样	标准	钴铬合金	待检	\N	样品库	\N	待检	2026-08-19 10:35:20.701094+08	2026-08-19 10:35:20.701094+08	\N	\N	\N	\N	\N	\N
BP20260819002-S01	4	BP20260819002	WT20260819002	定制式活动义齿	钴铬合金铸造支架树脂基托全口义齿	钴铬合金	待检	\N	样品库	\N	待检	2026-08-19 10:53:16.511048+08	2026-08-19 10:53:16.511048+08	\N	\N	\N	\N	\N	\N
BP20260819003-S01	5	BP20260819003	WT20260819003	定制式活动义齿	钴铬合金铸造支架树脂基托全口义齿	钴铬合金	待检	\N	样品库	\N	待检	2026-08-19 10:57:27.518316+08	2026-08-19 10:57:27.518316+08	\N	\N	\N	\N	\N	\N
BP20260819004-S01	6	BP20260819004	WT20260819004	定制式活动义齿	树脂切削基托全口义齿	树脂	待检	\N	样品库	\N	待检	2026-08-19 11:00:02.257423+08	2026-08-19 11:00:02.257423+08	\N	\N	\N	\N	\N	\N
BP20260819005-S01	7	BP20260819005	WT20260819004	定制式活动义齿	树脂基托可摘局部义齿	树脂	待检	\N	样品库	\N	待检	2026-08-19 11:00:02.266671+08	2026-08-19 11:00:02.266671+08	\N	\N	\N	\N	\N	\N
BP20260819006-S01	8	BP20260819006	WT20260819005	牙科用钴铬合金	标准	钴铬合金	待检	\N	样品库	\N	待检	2026-08-19 11:50:36.506391+08	2026-08-19 11:50:36.506391+08	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sessions (token, username, expires_at, created_at, last_activity_at) FROM stdin;
\.


--
-- Data for Name: signatures; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.signatures (username, source_file, image_file, uploaded_by, uploaded_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: task_config_snapshots; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.task_config_snapshots (task_no, config_id, config_version, snapshot_json, snapshot_hash, created_at) FROM stdin;
BP20260817001-T01	2	V2.0	{"fields": [{"id": 900, "config_id": 2, "field_key": "roller_radius", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "压头/支点半径R/mm", "is_readonly": false, "is_required": false, "field_default": "1", "field_options": "[]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 901, "config_id": 2, "field_key": "humidity_before", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测前湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 902, "config_id": 2, "field_key": "work_area_condition", "is_actual": false, "field_type": "multiselect", "sort_order": 0, "field_label": "工作区域实际状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "[\\"清洁\\",\\"干燥\\",\\"无明显粉尘\\",\\"无无关物品\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 903, "config_id": 2, "field_key": "humidity_after", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测后湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 904, "config_id": 2, "field_key": "equipment_traceability_confirmation", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "设备证书、有效期及溯源信息核对结果", "is_readonly": false, "is_required": false, "field_default": "已核对且在有效期内", "field_options": "[\\"已核对且在有效期内\\",\\"存在异常\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 905, "config_id": 2, "field_key": "parallel_block_parallelism", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "平行块平行度/mm", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 906, "config_id": 2, "field_key": "detection_location", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "检测地点", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 907, "config_id": 2, "field_key": "loading_speed", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "加载速度/mm/min", "is_readonly": false, "is_required": false, "field_default": "1.5", "field_options": "[]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 908, "config_id": 2, "field_key": "sample_preparation_actual", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "本次样品制备及表面状态说明", "is_readonly": false, "is_required": false, "field_default": "已按方法要求确认", "field_options": "[]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 909, "config_id": 2, "field_key": "centering_confirmation", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "试样居中及跨距确认", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 910, "config_id": 2, "field_key": "start_time", "is_actual": false, "field_type": "datetime", "sort_order": 0, "field_label": "实验开始时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 911, "config_id": 2, "field_key": "observation_method", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "裂纹萌生观察方式", "is_readonly": false, "is_required": false, "field_default": "目视和声响", "field_options": "[\\"声响\\",\\"目视\\"]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 912, "config_id": 2, "field_key": "end_time", "is_actual": false, "field_type": "datetime", "sort_order": 0, "field_label": "实验结束时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 913, "config_id": 2, "field_key": "parallel_check", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "夹具平行与居中确认", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 914, "config_id": 2, "field_key": "crack_observation_note", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "裂纹萌生/陶瓷剥离观察说明", "is_readonly": false, "is_required": false, "field_default": "按声响或目视结果判定", "field_options": "[]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 915, "config_id": 2, "field_key": "environment_interference", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "振动/气流影响", "is_readonly": false, "is_required": false, "field_default": "无明显干扰", "field_options": "[\\"无明显干扰\\",\\"有干扰\\"]", "section_order": 1, "section_title": "环境与设备"}, {"id": 916, "config_id": 2, "field_key": "metal_name", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "试样名称", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 917, "config_id": 2, "field_key": "work_area_status", "is_actual": false, "field_type": "multiselect", "sort_order": 0, "field_label": "试验区域状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "[\\"清洁\\",\\"干燥\\",\\"无明显粉尘\\",\\"无无关物品\\"]", "section_order": 1, "section_title": "环境与设备"}, {"id": 918, "config_id": 2, "field_key": "metal_batch", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "批号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 919, "config_id": 2, "field_key": "software", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "软件名称/版本", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 920, "config_id": 2, "field_key": "em_source", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "杨氏模量来源", "is_readonly": false, "is_required": false, "field_default": "说明书", "field_options": "[\\"说明书\\",\\"检测报告\\",\\"注册资料\\",\\"质保书\\",\\"其他\\"]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 921, "config_id": 2, "field_key": "em_source_file", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "杨氏模量来源文件编号", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 922, "config_id": 2, "field_key": "data_path", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "仪器原始数据保存路径", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 923, "config_id": 2, "field_key": "equipment_name", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "主要设备名称", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 924, "config_id": 2, "field_key": "orientation", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "试样放置方向", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[\\"金属面朝上、陶瓷面朝下\\",\\"其他\\"]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 925, "config_id": 2, "field_key": "equipment_model", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "设备型号/规格", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 926, "config_id": 2, "field_key": "parallel_block_no", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "平行块编号", "is_readonly": false, "is_required": false, "field_default": "BGGL-B019", "field_options": "[]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 927, "config_id": 2, "field_key": "test_date", "is_actual": false, "field_type": "date", "sort_order": 0, "field_label": "检测日期", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 928, "config_id": 2, "field_key": "fixture_no", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "金瓷结合试验夹具编号", "is_readonly": false, "is_required": false, "field_default": "BPGL-B009", "field_options": "[]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 929, "config_id": 2, "field_key": "temperature_compliance", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "本次温度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 930, "config_id": 2, "field_key": "support_span", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "支承跨距/mm", "is_readonly": false, "is_required": false, "field_default": "20", "field_options": "[]", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 931, "config_id": 2, "field_key": "temperature_before", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测前温度/℃", "is_readonly": false, "is_required": false, "field_default": "23", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 932, "config_id": 2, "field_key": "humidity_compliance", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "本次湿度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 933, "config_id": 2, "field_key": "interference_compliance", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "环境干扰控制是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 934, "config_id": 2, "field_key": "temperature_after", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测后温度/℃", "is_readonly": false, "is_required": false, "field_default": "23", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 935, "config_id": 2, "field_key": "equipment_no", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "设备管理编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 936, "config_id": 2, "field_key": "calibration_certificate", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "校准/检定证书编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 937, "config_id": 2, "field_key": "calibration_due", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "台账校准时间", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 938, "config_id": 2, "field_key": "equipment_status", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "使用前设备状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[\\"正常\\",\\"异常\\"]", "section_order": 1, "section_title": "环境与设备"}], "columns": [{"id": 290, "config_id": 2, "column_key": "sample_no", "sort_order": 0, "column_type": "text", "is_required": false, "column_label": "试样编号", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 291, "config_id": 2, "column_key": "width", "sort_order": 1, "column_type": "number", "is_required": false, "column_label": "宽度/mm", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 292, "config_id": 2, "column_key": "dm1", "sort_order": 2, "column_type": "number", "is_required": false, "column_label": "金属厚度1/mm", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 293, "config_id": 2, "column_key": "dm2", "sort_order": 3, "column_type": "number", "is_required": false, "column_label": "金属厚度2/mm", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 294, "config_id": 2, "column_key": "dm3", "sort_order": 4, "column_type": "number", "is_required": false, "column_label": "金属厚度3/mm", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 295, "config_id": 2, "column_key": "dm_mean", "sort_order": 5, "column_type": "calc", "is_required": false, "column_label": "金属厚度平均/mm", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"dm_mean\\", \\"op\\": \\"avg\\", \\"inputs\\": [\\"dm1\\", \\"dm2\\", \\"dm3\\"], \\"args\\": {\\"precision\\": 4}}"}, {"id": 296, "config_id": 2, "column_key": "em", "sort_order": 6, "column_type": "number", "is_required": false, "column_label": "金属弹性模量/GPa", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 297, "config_id": 2, "column_key": "k", "sort_order": 7, "column_type": "number", "is_required": false, "column_label": "K/mm⁻²", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 298, "config_id": 2, "column_key": "ffail", "sort_order": 8, "column_type": "number", "is_required": false, "column_label": "裂纹萌生力/N", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 299, "config_id": 2, "column_key": "tau", "sort_order": 9, "column_type": "calc", "is_required": false, "column_label": "结合强度/MPa", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"tau\\", \\"op\\": \\"multiply\\", \\"inputs\\": [\\"k\\", \\"ffail\\"], \\"args\\": {\\"precision\\": 2}}"}, {"id": 300, "config_id": 2, "column_key": "crack_position", "sort_order": 10, "column_type": "text", "is_required": false, "column_label": "开裂位置", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 301, "config_id": 2, "column_key": "failure_mode", "sort_order": 11, "column_type": "text", "is_required": false, "column_label": "断裂/剥离形态", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 302, "config_id": 2, "column_key": "curve_no", "sort_order": 12, "column_type": "text", "is_required": false, "column_label": "曲线/数据文件编号", "calc_precision": 3, "column_default": "", "calc_expression": null}, {"id": 303, "config_id": 2, "column_key": "conclusion", "sort_order": 13, "column_type": "calc", "is_required": false, "column_label": "单样结论", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"conclusion\\", \\"op\\": \\"gt\\", \\"inputs\\": [\\"tau\\"], \\"args\\": {\\"constant\\": 25, \\"true_value\\": \\"符合\\", \\"false_value\\": \\"不符合\\"}}"}, {"id": 304, "config_id": 2, "column_key": "note", "sort_order": 14, "column_type": "text", "is_required": false, "column_label": "备注", "calc_precision": 3, "column_default": "", "calc_expression": null}], "extra_json": {"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R004_MC_CRACK.docx", "report_decisive_photo_codes": ["MC_K_VALUE", "MC_REPORT"]}, "db_mappings": [{"col_index": 1, "field_key": "attachment_ref_t7", "row_index": 4, "transform": "text", "table_index": 7, "checkbox_selection": ""}, {"col_index": 1, "field_key": "count_conform", "row_index": 1, "transform": "text", "table_index": 7, "checkbox_selection": ""}, {"col_index": 1, "field_key": "em_record", "row_index": 2, "transform": "text", "table_index": 4, "checkbox_selection": ""}, {"col_index": 4, "field_key": "env_humidity_ok", "row_index": 2, "transform": "checkbox", "table_index": 1, "checkbox_selection": ""}, {"col_index": 4, "field_key": "env_temp_ok", "row_index": 1, "transform": "checkbox", "table_index": 1, "checkbox_selection": ""}, {"col_index": 1, "field_key": "final_verdict", "row_index": 5, "transform": "checkbox", "table_index": 7, "checkbox_selection": ""}, {"col_index": 2, "field_key": "fixture_record", "row_index": 1, "transform": "text", "table_index": 3, "checkbox_selection": ""}, {"col_index": 1, "field_key": "has_nonconform", "row_index": 2, "transform": "checkbox", "table_index": 7, "checkbox_selection": ""}, {"col_index": 3, "field_key": "humidity_after", "row_index": 2, "transform": "text", "table_index": 1, "checkbox_selection": ""}, {"col_index": 2, "field_key": "humidity_before", "row_index": 2, "transform": "text", "table_index": 1, "checkbox_selection": ""}, {"col_index": 1, "field_key": "k_value_note", "row_index": 3, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "parallel_block_parallelism", "row_index": 7, "transform": "text", "table_index": 3, "checkbox_selection": ""}, {"col_index": 2, "field_key": "parallel_block_record", "row_index": 6, "transform": "text", "table_index": 3, "checkbox_selection": ""}, {"col_index": 2, "field_key": "parallel_check_record", "row_index": 9, "transform": "text", "table_index": 3, "checkbox_selection": ""}, {"col_index": 2, "field_key": "roller_radius_record", "row_index": 3, "transform": "text", "table_index": 3, "checkbox_selection": ""}, {"col_index": 1, "field_key": "sample_record", "row_index": 1, "transform": "text", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "support_span_record", "row_index": 2, "transform": "text", "table_index": 3, "checkbox_selection": ""}, {"col_index": 3, "field_key": "temperature_after", "row_index": 1, "transform": "text", "table_index": 1, "checkbox_selection": ""}, {"col_index": 2, "field_key": "temperature_before", "row_index": 1, "transform": "text", "table_index": 1, "checkbox_selection": ""}]}	ec345684b8e8b2d3d7d39b2bc827af1efc13f1ac29d1d2e861f9a830f09baed1	2026-08-17 15:09:11.022644+08
BP20260818001-T01	17	V2.1	{"fields": [{"id": 3835, "config_id": 17, "field_key": "test_date", "is_actual": false, "field_type": "date", "sort_order": 0, "field_label": "检测日期", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3836, "config_id": 17, "field_key": "standard_block", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "标准粗糙度样板编号", "is_readonly": false, "is_required": false, "field_default": "BPGL-B001", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3837, "config_id": 17, "field_key": "temperature_compliance", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "本次温度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3838, "config_id": 17, "field_key": "humidity_compliance", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "本次湿度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3839, "config_id": 17, "field_key": "temperature_before", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测前温度/℃", "is_readonly": false, "is_required": false, "field_default": "23", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3840, "config_id": 17, "field_key": "standard_block_nominal", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "标准样板标称值/μm", "is_readonly": false, "is_required": false, "field_default": "3", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3841, "config_id": 17, "field_key": "repeat_check_1", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "标准样板实测值1/μm", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3842, "config_id": 17, "field_key": "temperature_after", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测后温度/℃", "is_readonly": false, "is_required": false, "field_default": "23", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3843, "config_id": 17, "field_key": "interference_compliance", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "环境干扰控制是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3844, "config_id": 17, "field_key": "humidity_before", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测前湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3845, "config_id": 17, "field_key": "repeat_check_2", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "标准样板实测值2/μm", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3846, "config_id": 17, "field_key": "work_area_condition", "is_actual": false, "field_type": "multiselect", "sort_order": 0, "field_label": "工作区域实际状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "[\\"清洁\\",\\"干燥\\",\\"无明显粉尘\\",\\"无无关物品\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3847, "config_id": 17, "field_key": "equipment_traceability_confirmation", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "设备证书、有效期及溯源信息核对结果", "is_readonly": false, "is_required": false, "field_default": "已核对且在有效期内", "field_options": "[\\"已核对且在有效期内\\",\\"存在异常\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3848, "config_id": 17, "field_key": "humidity_after", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测后湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3849, "config_id": 17, "field_key": "repeat_check_3", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "标准样板实测值3/μm", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3850, "config_id": 17, "field_key": "detection_location", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "检测地点", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3851, "config_id": 17, "field_key": "sample_production_date", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "样品生产日期/批次日期", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3852, "config_id": 17, "field_key": "standard_block_result", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "标准样板核查结果", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[\\"合格\\",\\"不合格\\"]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3853, "config_id": 17, "field_key": "calculation_standard", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "计算标准", "is_readonly": false, "is_required": false, "field_default": "ISO-97", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3854, "config_id": 17, "field_key": "start_time", "is_actual": false, "field_type": "datetime", "sort_order": 0, "field_label": "实验开始时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3855, "config_id": 17, "field_key": "sample_preparation_actual", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "本次样品制备及表面状态说明", "is_readonly": false, "is_required": false, "field_default": "已按方法要求确认", "field_options": "[]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3856, "config_id": 17, "field_key": "method_execution_confirmation", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "本次操作与受控方法一致性", "is_readonly": false, "is_required": false, "field_default": "一致", "field_options": "[\\"一致\\",\\"存在偏离\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3857, "config_id": 17, "field_key": "end_time", "is_actual": false, "field_type": "datetime", "sort_order": 0, "field_label": "实验结束时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3858, "config_id": 17, "field_key": "shape_removal", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "形状去除", "is_readonly": false, "is_required": false, "field_default": "自动", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3859, "config_id": 17, "field_key": "filter_type", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "滤波器", "is_readonly": false, "is_required": false, "field_default": "高斯", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3860, "config_id": 17, "field_key": "z_axis_marking", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "Z轴正方向标识", "is_readonly": false, "is_required": false, "field_default": "清晰", "field_options": "[\\"清晰\\",\\"不清晰\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3861, "config_id": 17, "field_key": "environment_interference", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "振动/气流影响", "is_readonly": false, "is_required": false, "field_default": "无明显干扰", "field_options": "[\\"无明显干扰\\",\\"有干扰\\"]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3862, "config_id": 17, "field_key": "surface_cleaning_actual", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "测试面清洁状态", "is_readonly": false, "is_required": false, "field_default": "清洁", "field_options": "[\\"清洁\\",\\"不清洁\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3863, "config_id": 17, "field_key": "lambda_s", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "λs", "is_readonly": false, "is_required": false, "field_default": "自动", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3864, "config_id": 17, "field_key": "work_area_status", "is_actual": false, "field_type": "multiselect", "sort_order": 0, "field_label": "试验区域状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "[\\"清洁\\",\\"干燥\\",\\"无明显粉尘\\",\\"无无关物品\\"]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3865, "config_id": 17, "field_key": "fixture_stability", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "试样固定及工作台稳定性", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3866, "config_id": 17, "field_key": "software", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "软件名称/版本", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3867, "config_id": 17, "field_key": "measurement_range", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "测量范围/μm", "is_readonly": false, "is_required": false, "field_default": "40", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3868, "config_id": 17, "field_key": "measurement_line_note", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "实际测量线/方向说明", "is_readonly": false, "is_required": false, "field_default": "按受控方法规定位置测量", "field_options": "[]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3869, "config_id": 17, "field_key": "sampling_length", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "取样长度/mm", "is_readonly": false, "is_required": false, "field_default": "0.8", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3870, "config_id": 17, "field_key": "data_path", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "仪器原始数据保存路径", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3871, "config_id": 17, "field_key": "sampling_count", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "取样个数", "is_readonly": false, "is_required": false, "field_default": "5", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3872, "config_id": 17, "field_key": "equipment_name", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "主要设备名称", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3873, "config_id": 17, "field_key": "equipment_model", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "设备型号/规格", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3874, "config_id": 17, "field_key": "evaluation_length", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "评定长度/mm", "is_readonly": false, "is_required": false, "field_default": "4", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3875, "config_id": 17, "field_key": "measuring_speed", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "测量速度/mm/s", "is_readonly": false, "is_required": false, "field_default": "0.5", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3876, "config_id": 17, "field_key": "equipment_no", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "设备管理编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3877, "config_id": 17, "field_key": "calibration_certificate", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "校准/检定证书编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3878, "config_id": 17, "field_key": "cutoff_filter", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "滤波/计算标准", "is_readonly": false, "is_required": false, "field_default": "高斯", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3879, "config_id": 17, "field_key": "calibration_due", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "台账校准时间", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3880, "config_id": 17, "field_key": "probe_condition", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "探针状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[\\"正常\\",\\"异常\\"]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3881, "config_id": 17, "field_key": "equipment_status", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "使用前设备状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[\\"正常\\",\\"异常\\"]", "section_order": 1, "section_title": "环境与设备"}, {"id": 3882, "config_id": 17, "field_key": "platform_level", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "工作台水平状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3883, "config_id": 17, "field_key": "surface_state", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "试样表面状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[\\"原打印表面\\",\\"经处理表面\\",\\"其他\\"]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3884, "config_id": 17, "field_key": "measurement_direction", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "测量方向/线位", "is_readonly": false, "is_required": false, "field_default": "3条平行、不重叠、代表性测量线", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 3885, "config_id": 17, "field_key": "three_length_mode", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "评定长度方式", "is_readonly": false, "is_required": false, "field_default": "5L（默认）", "field_options": "[\\"5L（默认）\\",\\"3L（已完成方法确认）\\"]", "section_order": 2, "section_title": "试验参数与使用前确认"}], "columns": [{"id": 1123, "config_id": 17, "column_key": "sample_no", "sort_order": 0, "column_type": "text", "is_required": false, "column_label": "试样编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1124, "config_id": 17, "column_key": "surface_confirm", "sort_order": 1, "column_type": "select:符合|不符合", "is_required": false, "column_label": "原打印面/方向确认", "calc_precision": 3, "column_default": "符合", "calc_expression": ""}, {"id": 1125, "config_id": 17, "column_key": "position", "sort_order": 2, "column_type": "text", "is_required": false, "column_label": "测量位置", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1126, "config_id": 17, "column_key": "ra1", "sort_order": 3, "column_type": "number", "is_required": false, "column_label": "Ra1/μm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1127, "config_id": 17, "column_key": "ra2", "sort_order": 4, "column_type": "number", "is_required": false, "column_label": "Ra2/μm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1128, "config_id": 17, "column_key": "ra3", "sort_order": 5, "column_type": "number", "is_required": false, "column_label": "Ra3/μm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1129, "config_id": 17, "column_key": "mean", "sort_order": 6, "column_type": "calc", "is_required": false, "column_label": "平均值/μm", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\":\\"mean\\",\\"op\\":\\"avg\\",\\"inputs\\":[\\"ra1\\",\\"ra2\\",\\"ra3\\"],\\"args\\":{\\"precision\\":3}}"}, {"id": 1130, "config_id": 17, "column_key": "limit", "sort_order": 7, "column_type": "number", "is_required": false, "column_label": "判定限值/μm", "calc_precision": 3, "column_default": "15", "calc_expression": ""}, {"id": 1131, "config_id": 17, "column_key": "conclusion", "sort_order": 8, "column_type": "calc", "is_required": false, "column_label": "单样结论", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\":\\"conclusion\\",\\"op\\":\\"le\\",\\"inputs\\":[\\"mean\\",\\"limit\\"],\\"args\\":{\\"constant\\":15,\\"true_value\\":\\"符合\\",\\"false_value\\":\\"不符合\\"}}"}, {"id": 1132, "config_id": 17, "column_key": "retest_mean", "sort_order": 9, "column_type": "number", "is_required": false, "column_label": "复测后平均/μm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1133, "config_id": 17, "column_key": "file_no", "sort_order": 10, "column_type": "text", "is_required": false, "column_label": "曲线/数据文件编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1134, "config_id": 17, "column_key": "note", "sort_order": 11, "column_type": "text", "is_required": false, "column_label": "备注", "calc_precision": 3, "column_default": "", "calc_expression": ""}], "extra_json": {"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "R001_表面粗糙度试验_CMA原始记录表.docx", "report_decisive_photo_codes": ["ROUGH_POINT_1", "ROUGH_CURVE_RESULT"]}, "db_mappings": [{"col_index": 2, "field_key": "calculation_standard", "row_index": 1, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "calculation_standard_ok", "row_index": 1, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 4, "field_key": "clean_ok", "row_index": 4, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "clean_status", "row_index": 4, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "cutoff_filter", "row_index": 3, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "cutoff_filter_ok", "row_index": 3, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 5, "field_key": "deviation_affects_result", "row_index": 1, "transform": "checkbox", "table_index": 9, "checkbox_selection": ""}, {"col_index": 2, "field_key": "deviation_record", "row_index": 1, "transform": "raw", "table_index": 9, "checkbox_selection": ""}, {"col_index": 4, "field_key": "dust_ok", "row_index": 5, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "dust_status", "row_index": 5, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 4, "field_key": "env_humidity_ok", "row_index": 2, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 4, "field_key": "env_temp_ok", "row_index": 1, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 3, "field_key": "evaluation_length_ok", "row_index": 7, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "evaluation_length_ok2", "row_index": 9, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "evaluation_length_value", "row_index": 7, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "evaluation_length_value2", "row_index": 9, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 1, "field_key": "final_conclusion", "row_index": 6, "transform": "text", "table_index": 8, "checkbox_selection": ""}, {"col_index": 1, "field_key": "final_verdict", "row_index": 5, "transform": "checkbox", "table_index": 8, "checkbox_selection": ""}, {"col_index": 3, "field_key": "fixture_conclusion", "row_index": 2, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "fixture_record", "row_index": 2, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "humidity_after", "row_index": 2, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "humidity_before", "row_index": 2, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "interference_col2", "row_index": 3, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 3, "field_key": "interference_col3", "row_index": 3, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 4, "field_key": "interference_ok", "row_index": 3, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "lambda_s", "row_index": 2, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "lambda_s_ok", "row_index": 2, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "measurement_direction", "row_index": 10, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "measurement_direction_ok", "row_index": 10, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "measurement_range", "row_index": 5, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "measurement_range_ok", "row_index": 5, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "overall_conclusion", "row_index": 6, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "overall_record", "row_index": 6, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "platform_conclusion", "row_index": 1, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "platform_record", "row_index": 1, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "probe_conclusion", "row_index": 5, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "probe_record", "row_index": 5, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "repeat_conclusion", "row_index": 4, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "repeat_record", "row_index": 4, "transform": "raw", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "sampling_count_ok", "row_index": 8, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 1, "field_key": "sampling_count_select", "row_index": 8, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "sampling_count_value", "row_index": 8, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "sampling_length_ok", "row_index": 6, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 1, "field_key": "sampling_length_select", "row_index": 6, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "sampling_length_value", "row_index": 6, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "shape_removal", "row_index": 4, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "shape_removal_ok", "row_index": 4, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "standard_block_conclusion", "row_index": 3, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "standard_block_record", "row_index": 3, "transform": "raw", "table_index": 4, "checkbox_selection": ""}, {"col_index": 1, "field_key": "statistics_failed", "row_index": 2, "transform": "checkbox", "table_index": 8, "checkbox_selection": ""}, {"col_index": 1, "field_key": "statistics_minmax", "row_index": 1, "transform": "raw", "table_index": 8, "checkbox_selection": ""}, {"col_index": 3, "field_key": "temperature_after", "row_index": 1, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "temperature_before", "row_index": 1, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "three_length_applicable", "row_index": 0, "transform": "checkbox", "table_index": 6, "checkbox_selection": ""}, {"col_index": 1, "field_key": "three_length_conclusion", "row_index": 3, "transform": "checkbox", "table_index": 8, "checkbox_selection": ""}, {"col_index": 1, "field_key": "three_length_not_applicable", "row_index": 0, "transform": "checkbox", "table_index": 6, "checkbox_selection": ""}]}	09baaf3942e98991d42a1d091e0aa699e533d4a9b4e5985a9d7c3958d4837a72	2026-08-18 14:38:18.237151+08
BP20260818001-T02	8	V2.0	{"fields": [{"id": 3533, "config_id": 8, "field_key": "temperature_compliance", "is_actual": true, "field_type": "select", "sort_order": 1, "field_label": "本次温度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3501, "config_id": 8, "field_key": "test_date", "is_actual": false, "field_type": "date", "sort_order": 1, "field_label": "检测日期", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3500, "config_id": 8, "field_key": "sample_production_date", "is_actual": false, "field_type": "text", "sort_order": 1, "field_label": "样品批号", "is_readonly": true, "is_required": false, "field_default": null, "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3534, "config_id": 8, "field_key": "humidity_compliance", "is_actual": true, "field_type": "select", "sort_order": 2, "field_label": "本次湿度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3519, "config_id": 8, "field_key": "method", "is_actual": false, "field_type": "text", "sort_order": 2, "field_label": "试验力级别", "is_readonly": false, "is_required": false, "field_default": "HV10", "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3502, "config_id": 8, "field_key": "temperature_before", "is_actual": true, "field_type": "number", "sort_order": 2, "field_label": "检测前温度/℃", "is_readonly": false, "is_required": false, "field_default": "23.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3520, "config_id": 8, "field_key": "test_force", "is_actual": false, "field_type": "number", "sort_order": 3, "field_label": "试验力/N", "is_readonly": false, "is_required": false, "field_default": "98.07", "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3503, "config_id": 8, "field_key": "temperature_after", "is_actual": true, "field_type": "number", "sort_order": 3, "field_label": "检测后温度/℃", "is_readonly": false, "is_required": false, "field_default": "23.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3535, "config_id": 8, "field_key": "interference_compliance", "is_actual": true, "field_type": "select", "sort_order": 3, "field_label": "环境干扰控制是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3536, "config_id": 8, "field_key": "work_area_condition", "is_actual": true, "field_type": "multiselect", "sort_order": 4, "field_label": "工作区域实际状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "清洁,干燥,无明显粉尘,无无关物品", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3504, "config_id": 8, "field_key": "humidity_before", "is_actual": true, "field_type": "number", "sort_order": 4, "field_label": "检测前湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3521, "config_id": 8, "field_key": "dwell_time", "is_actual": false, "field_type": "number", "sort_order": 4, "field_label": "保荷时间/s", "is_readonly": false, "is_required": false, "field_default": "15.0", "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3522, "config_id": 8, "field_key": "standard_block_no", "is_actual": false, "field_type": "text", "sort_order": 5, "field_label": "标准硬度块编号", "is_readonly": false, "is_required": false, "field_default": "BPGL-B007", "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3537, "config_id": 8, "field_key": "equipment_traceability_confirmation", "is_actual": true, "field_type": "select", "sort_order": 5, "field_label": "设备证书、有效期及溯源信息核对结果", "is_readonly": false, "is_required": false, "field_default": "已核对且在有效期内", "field_options": "已核对且在有效期内,存在异常", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3505, "config_id": 8, "field_key": "humidity_after", "is_actual": true, "field_type": "number", "sort_order": 5, "field_label": "检测后湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3523, "config_id": 8, "field_key": "standard_block_nominal", "is_actual": false, "field_type": "number", "sort_order": 6, "field_label": "标准硬度块标称值/HV", "is_readonly": false, "is_required": false, "field_default": "466.0", "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3506, "config_id": 8, "field_key": "detection_location", "is_actual": false, "field_type": "text", "sort_order": 6, "field_label": "检测地点", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3538, "config_id": 8, "field_key": "sample_preparation_actual", "is_actual": true, "field_type": "text", "sort_order": 6, "field_label": "本次样品制备及表面状态说明", "is_readonly": false, "is_required": false, "field_default": "已按方法要求确认", "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3539, "config_id": 8, "field_key": "method_execution_confirmation", "is_actual": true, "field_type": "select", "sort_order": 7, "field_label": "本次操作与受控方法一致性", "is_readonly": false, "is_required": false, "field_default": "一致", "field_options": "一致,存在偏离", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3507, "config_id": 8, "field_key": "start_time", "is_actual": true, "field_type": "datetime", "sort_order": 7, "field_label": "实验开始时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3524, "config_id": 8, "field_key": "standard_block_due", "is_actual": false, "field_type": "date", "sort_order": 7, "field_label": "标准硬度块有效期", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3540, "config_id": 8, "field_key": "surface_preparation_hv", "is_actual": true, "field_type": "text", "sort_order": 8, "field_label": "测试面磨制/抛光及清洁状态", "is_readonly": false, "is_required": false, "field_default": "表面平整清洁且不影响压痕", "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3508, "config_id": 8, "field_key": "end_time", "is_actual": true, "field_type": "datetime", "sort_order": 8, "field_label": "实验结束时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3525, "config_id": 8, "field_key": "standard_block_reading_1", "is_actual": true, "field_type": "number", "sort_order": 8, "field_label": "标准硬度块实测值1/HV", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3526, "config_id": 8, "field_key": "standard_block_reading_2", "is_actual": true, "field_type": "number", "sort_order": 9, "field_label": "标准硬度块实测值2/HV", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3509, "config_id": 8, "field_key": "environment_interference", "is_actual": false, "field_type": "select", "sort_order": 9, "field_label": "振动/气流影响", "is_readonly": false, "is_required": false, "field_default": "无明显干扰", "field_options": "无明显干扰,有干扰", "section_order": 1, "section_title": "环境与设备"}, {"id": 3541, "config_id": 8, "field_key": "software_version_actual", "is_actual": true, "field_type": "text", "sort_order": 9, "field_label": "本次硬度测量软件版本", "is_readonly": false, "is_required": false, "field_default": "由设备配置核对", "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3542, "config_id": 8, "field_key": "loading_unloading_confirmation", "is_actual": true, "field_type": "select", "sort_order": 10, "field_label": "加载、保荷及卸载过程", "is_readonly": false, "is_required": false, "field_default": "正常", "field_options": "正常,异常", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3527, "config_id": 8, "field_key": "standard_block_reading_3", "is_actual": true, "field_type": "number", "sort_order": 10, "field_label": "标准硬度块实测值3/HV", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3510, "config_id": 8, "field_key": "work_area_status", "is_actual": false, "field_type": "multiselect", "sort_order": 10, "field_label": "试验区域状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "清洁,干燥,无明显粉尘,无无关物品", "section_order": 1, "section_title": "环境与设备"}, {"id": 3528, "config_id": 8, "field_key": "standard_block_result", "is_actual": false, "field_type": "select", "sort_order": 11, "field_label": "标准硬度块核查结果", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "合格,不合格", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3511, "config_id": 8, "field_key": "software", "is_actual": false, "field_type": "text", "sort_order": 11, "field_label": "软件名称/版本", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3512, "config_id": 8, "field_key": "data_path", "is_actual": false, "field_type": "text", "sort_order": 12, "field_label": "仪器原始数据保存路径", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3529, "config_id": 8, "field_key": "surface_condition", "is_actual": false, "field_type": "select", "sort_order": 12, "field_label": "测试面状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "平整清洁,异常", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3530, "config_id": 8, "field_key": "perpendicularity", "is_actual": false, "field_type": "select", "sort_order": 13, "field_label": "试样垂直性确认", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "符合,不符合", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3513, "config_id": 8, "field_key": "equipment_name", "is_actual": false, "field_type": "text", "sort_order": 13, "field_label": "主要设备名称", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3531, "config_id": 8, "field_key": "indent_measurement_method", "is_actual": false, "field_type": "text", "sort_order": 14, "field_label": "压痕测量方式", "is_readonly": false, "is_required": false, "field_default": "切线测量", "field_options": "", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3514, "config_id": 8, "field_key": "equipment_model", "is_actual": false, "field_type": "text", "sort_order": 14, "field_label": "设备型号/规格", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3515, "config_id": 8, "field_key": "equipment_no", "is_actual": false, "field_type": "text", "sort_order": 15, "field_label": "设备管理编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3532, "config_id": 8, "field_key": "report_exported", "is_actual": false, "field_type": "select", "sort_order": 15, "field_label": "硬度报告已导出", "is_readonly": false, "is_required": false, "field_default": "是", "field_options": "是,否", "section_order": 2, "section_title": "硬度和试样表面确认"}, {"id": 3516, "config_id": 8, "field_key": "calibration_certificate", "is_actual": false, "field_type": "text", "sort_order": 16, "field_label": "校准/检定证书编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3517, "config_id": 8, "field_key": "calibration_due", "is_actual": false, "field_type": "text", "sort_order": 17, "field_label": "台账校准时间", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3518, "config_id": 8, "field_key": "equipment_status", "is_actual": false, "field_type": "select", "sort_order": 18, "field_label": "使用前设备状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "正常,异常", "section_order": 1, "section_title": "环境与设备"}], "columns": [{"id": 1031, "config_id": 8, "column_key": "sample_no", "sort_order": 1, "column_type": "text", "is_required": true, "column_label": "样品编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1032, "config_id": 8, "column_key": "face", "sort_order": 2, "column_type": "text", "is_required": true, "column_label": "测量方向", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1033, "config_id": 8, "column_key": "indent1", "sort_order": 3, "column_type": "number", "is_required": true, "column_label": "压痕1/HV", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1034, "config_id": 8, "column_key": "indent2", "sort_order": 4, "column_type": "number", "is_required": true, "column_label": "压痕2/HV", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1035, "config_id": 8, "column_key": "indent3", "sort_order": 5, "column_type": "number", "is_required": true, "column_label": "压痕3/HV", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1036, "config_id": 8, "column_key": "mean", "sort_order": 6, "column_type": "calc", "is_required": true, "column_label": "测试面平均/HV", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"mean\\", \\"op\\": \\"avg\\", \\"inputs\\": [\\"indent1\\", \\"indent2\\", \\"indent3\\"], \\"args\\": {\\"precision\\": 1}}"}, {"id": 1037, "config_id": 8, "column_key": "indent_quality", "sort_order": 7, "column_type": "select", "is_required": true, "column_label": "压痕有效性", "calc_precision": 3, "column_default": "有效|无效", "calc_expression": ""}, {"id": 1038, "config_id": 8, "column_key": "image_no", "sort_order": 8, "column_type": "text", "is_required": true, "column_label": "压痕图像编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1039, "config_id": 8, "column_key": "note", "sort_order": 9, "column_type": "text", "is_required": true, "column_label": "备注", "calc_precision": 3, "column_default": "", "calc_expression": ""}], "extra_json": {"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R011_VICKERS.docx", "report_decisive_photo_codes": ["HV_REPORT_1"]}, "db_mappings": [{"col_index": 1, "field_key": "indent_method", "row_index": 1, "transform": "checkbox", "table_index": 3, "checkbox_selection": ""}, {"col_index": 5, "field_key": "perpendicularity", "row_index": 5, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 3, "field_key": "report_exported", "row_index": 2, "transform": "checkbox", "table_index": 3, "checkbox_selection": ""}, {"col_index": 5, "field_key": "report_exported_ok", "row_index": 2, "transform": "checkbox", "table_index": 3, "checkbox_selection": ""}, {"col_index": 5, "field_key": "standard_block_due", "row_index": 1, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 3, "field_key": "std_reading_1", "row_index": 2, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 5, "field_key": "std_reading_2", "row_index": 2, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 1, "field_key": "std_reading_3", "row_index": 3, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 3, "field_key": "std_reading_mean", "row_index": 3, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 5, "field_key": "std_result", "row_index": 3, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 1, "field_key": "surface_condition", "row_index": 5, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 5, "field_key": "surface_verdict", "row_index": 4, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}]}	2b330f3cf87e7a5089e3a5b111995a21a38079b1d502804f724a67bd3da7ece8	2026-08-18 14:38:18.237151+08
BP20260818001-T03	13	V2.0	{"fields": [{"id": 3754, "config_id": 13, "field_key": "test_date", "is_actual": false, "field_type": "date", "sort_order": 1, "field_label": "检测日期", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3772, "config_id": 13, "field_key": "balance_internal_calibration", "is_actual": false, "field_type": "select", "sort_order": 1, "field_label": "天平内校准结果", "is_readonly": false, "is_required": false, "field_default": "合格", "field_options": "合格,不合格", "section_order": 2, "section_title": "密度系统与判定依据"}, {"id": 3779, "config_id": 13, "field_key": "temperature_compliance", "is_actual": true, "field_type": "select", "sort_order": 1, "field_label": "本次温度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3780, "config_id": 13, "field_key": "humidity_compliance", "is_actual": true, "field_type": "select", "sort_order": 2, "field_label": "本次湿度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3755, "config_id": 13, "field_key": "temperature_before", "is_actual": true, "field_type": "number", "sort_order": 2, "field_label": "检测前温度/℃", "is_readonly": false, "is_required": false, "field_default": "23.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3773, "config_id": 13, "field_key": "density_block_no", "is_actual": false, "field_type": "text", "sort_order": 2, "field_label": "标准密度块/核查样编号", "is_readonly": false, "is_required": false, "field_default": "BPGL-B023", "field_options": "", "section_order": 2, "section_title": "密度系统与判定依据"}, {"id": 3774, "config_id": 13, "field_key": "system_check_result", "is_actual": false, "field_type": "select", "sort_order": 3, "field_label": "密度系统核查结果", "is_readonly": false, "is_required": false, "field_default": "合格", "field_options": "合格,不合格", "section_order": 2, "section_title": "密度系统与判定依据"}, {"id": 3756, "config_id": 13, "field_key": "temperature_after", "is_actual": true, "field_type": "number", "sort_order": 3, "field_label": "检测后温度/℃", "is_readonly": false, "is_required": false, "field_default": "23.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3781, "config_id": 13, "field_key": "interference_compliance", "is_actual": true, "field_type": "select", "sort_order": 3, "field_label": "环境干扰控制是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3757, "config_id": 13, "field_key": "humidity_before", "is_actual": true, "field_type": "number", "sort_order": 4, "field_label": "检测前湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3775, "config_id": 13, "field_key": "auto_calc_check", "is_actual": false, "field_type": "select", "sort_order": 4, "field_label": "自动计算验证", "is_readonly": false, "is_required": false, "field_default": "一致", "field_options": "一致,不一致", "section_order": 2, "section_title": "密度系统与判定依据"}, {"id": 3782, "config_id": 13, "field_key": "work_area_condition", "is_actual": true, "field_type": "multiselect", "sort_order": 4, "field_label": "工作区域实际状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "清洁,干燥,无明显粉尘,无无关物品", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3783, "config_id": 13, "field_key": "equipment_traceability_confirmation", "is_actual": true, "field_type": "select", "sort_order": 5, "field_label": "设备证书、有效期及溯源信息核对结果", "is_readonly": false, "is_required": false, "field_default": "已核对且在有效期内", "field_options": "已核对且在有效期内,存在异常", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3758, "config_id": 13, "field_key": "humidity_after", "is_actual": true, "field_type": "number", "sort_order": 5, "field_label": "检测后湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3776, "config_id": 13, "field_key": "water_type", "is_actual": false, "field_type": "text", "sort_order": 5, "field_label": "浸没液", "is_readonly": false, "is_required": false, "field_default": "三级水", "field_options": "", "section_order": 2, "section_title": "密度系统与判定依据"}, {"id": 3753, "config_id": 13, "field_key": "sample_production_date", "is_actual": false, "field_type": "text", "sort_order": 6, "field_label": "样品生产日期/批次日期", "is_readonly": true, "is_required": false, "field_default": null, "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3759, "config_id": 13, "field_key": "detection_location", "is_actual": false, "field_type": "text", "sort_order": 6, "field_label": "检测地点", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3777, "config_id": 13, "field_key": "declared_density", "is_actual": true, "field_type": "number", "sort_order": 6, "field_label": "可追溯声明密度/(g/cm³)", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "密度系统与判定依据"}, {"id": 3778, "config_id": 13, "field_key": "declared_density_source", "is_actual": true, "field_type": "text", "sort_order": 7, "field_label": "声明密度来源文件", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "密度系统与判定依据"}, {"id": 3760, "config_id": 13, "field_key": "start_time", "is_actual": true, "field_type": "datetime", "sort_order": 7, "field_label": "实验开始时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3784, "config_id": 13, "field_key": "sample_preparation_actual", "is_actual": true, "field_type": "text", "sort_order": 7, "field_label": "本次样品制备及表面状态说明", "is_readonly": false, "is_required": false, "field_default": "已按方法要求确认", "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3785, "config_id": 13, "field_key": "method_execution_confirmation", "is_actual": true, "field_type": "select", "sort_order": 8, "field_label": "本次操作与受控方法一致性", "is_readonly": false, "is_required": false, "field_default": "一致", "field_options": "一致,存在偏离", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3761, "config_id": 13, "field_key": "end_time", "is_actual": true, "field_type": "datetime", "sort_order": 8, "field_label": "实验结束时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3762, "config_id": 13, "field_key": "environment_interference", "is_actual": false, "field_type": "select", "sort_order": 9, "field_label": "振动/气流影响", "is_readonly": false, "is_required": false, "field_default": "无明显干扰", "field_options": "无明显干扰,有干扰", "section_order": 1, "section_title": "环境与设备"}, {"id": 3786, "config_id": 13, "field_key": "cleaning_confirmation", "is_actual": true, "field_type": "select", "sort_order": 9, "field_label": "试样清洗状态确认", "is_readonly": false, "is_required": false, "field_default": "已清洗", "field_options": "已清洗,未清洗", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3787, "config_id": 13, "field_key": "buoyancy_medium_note", "is_actual": true, "field_type": "text", "sort_order": 10, "field_label": "浸没介质（纯水）状态说明", "is_readonly": false, "is_required": false, "field_default": "纯水温度已稳定至23±0.2℃", "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3763, "config_id": 13, "field_key": "work_area_status", "is_actual": false, "field_type": "multiselect", "sort_order": 10, "field_label": "试验区域状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "清洁,干燥,无明显粉尘,无无关物品", "section_order": 1, "section_title": "环境与设备"}, {"id": 3788, "config_id": 13, "field_key": "balance_zero_check", "is_actual": true, "field_type": "select", "sort_order": 11, "field_label": "天平调零及稳定确认", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3764, "config_id": 13, "field_key": "software", "is_actual": false, "field_type": "text", "sort_order": 11, "field_label": "软件名称/版本", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3789, "config_id": 13, "field_key": "bubble_check", "is_actual": true, "field_type": "select", "sort_order": 12, "field_label": "试样浸没气泡附着检查", "is_readonly": false, "is_required": false, "field_default": "无气泡", "field_options": "无气泡,有气泡", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3765, "config_id": 13, "field_key": "data_path", "is_actual": false, "field_type": "text", "sort_order": 12, "field_label": "仪器原始数据保存路径", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3766, "config_id": 13, "field_key": "equipment_name", "is_actual": false, "field_type": "text", "sort_order": 13, "field_label": "主要设备名称", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3790, "config_id": 13, "field_key": "standard_block_verification", "is_actual": true, "field_type": "select", "sort_order": 13, "field_label": "标准密度块/参考标准核查", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3767, "config_id": 13, "field_key": "equipment_model", "is_actual": false, "field_type": "text", "sort_order": 14, "field_label": "设备型号/规格", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3768, "config_id": 13, "field_key": "equipment_no", "is_actual": false, "field_type": "text", "sort_order": 15, "field_label": "设备管理编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3769, "config_id": 13, "field_key": "calibration_certificate", "is_actual": false, "field_type": "text", "sort_order": 16, "field_label": "校准/检定证书编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3770, "config_id": 13, "field_key": "calibration_due", "is_actual": false, "field_type": "text", "sort_order": 17, "field_label": "台账校准时间", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3771, "config_id": 13, "field_key": "equipment_status", "is_actual": false, "field_type": "select", "sort_order": 18, "field_label": "使用前设备状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "正常,异常", "section_order": 1, "section_title": "环境与设备"}], "columns": [{"id": 1087, "config_id": 13, "column_key": "sample_no", "sort_order": 1, "column_type": "text", "is_required": true, "column_label": "试样编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1088, "config_id": 13, "column_key": "a1", "sort_order": 2, "column_type": "number", "is_required": true, "column_label": "测量1空气中质量A/g", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1089, "config_id": 13, "column_key": "b1", "sort_order": 3, "column_type": "number", "is_required": true, "column_label": "测量1水中表观质量B/g", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1090, "config_id": 13, "column_key": "water_temp1", "sort_order": 4, "column_type": "number", "is_required": true, "column_label": "测量1水温/℃", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1091, "config_id": 13, "column_key": "water_density1", "sort_order": 5, "column_type": "number", "is_required": true, "column_label": "测量1水密度/(g/cm³)", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1092, "config_id": 13, "column_key": "auto_density1", "sort_order": 6, "column_type": "number", "is_required": true, "column_label": "测量1天平密度", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1093, "config_id": 13, "column_key": "density1", "sort_order": 7, "column_type": "calc", "is_required": true, "column_label": "测量1复算密度", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1094, "config_id": 13, "column_key": "a2", "sort_order": 8, "column_type": "number", "is_required": true, "column_label": "测量2空气中质量A/g", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1095, "config_id": 13, "column_key": "b2", "sort_order": 9, "column_type": "number", "is_required": true, "column_label": "测量2水中表观质量B/g", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1096, "config_id": 13, "column_key": "water_temp2", "sort_order": 10, "column_type": "number", "is_required": true, "column_label": "测量2水温/℃", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1097, "config_id": 13, "column_key": "water_density2", "sort_order": 11, "column_type": "number", "is_required": true, "column_label": "测量2水密度/(g/cm³)", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1098, "config_id": 13, "column_key": "auto_density2", "sort_order": 12, "column_type": "number", "is_required": true, "column_label": "测量2天平密度", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1099, "config_id": 13, "column_key": "density2", "sort_order": 13, "column_type": "calc", "is_required": true, "column_label": "测量2复算密度", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1100, "config_id": 13, "column_key": "a3", "sort_order": 14, "column_type": "number", "is_required": true, "column_label": "测量3空气中质量A/g", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1101, "config_id": 13, "column_key": "b3", "sort_order": 15, "column_type": "number", "is_required": true, "column_label": "测量3水中表观质量B/g", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1102, "config_id": 13, "column_key": "water_temp3", "sort_order": 16, "column_type": "number", "is_required": true, "column_label": "测量3水温/℃", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1103, "config_id": 13, "column_key": "water_density3", "sort_order": 17, "column_type": "number", "is_required": true, "column_label": "测量3水密度/(g/cm³)", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1104, "config_id": 13, "column_key": "auto_density3", "sort_order": 18, "column_type": "number", "is_required": true, "column_label": "测量3天平密度", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1105, "config_id": 13, "column_key": "density3", "sort_order": 19, "column_type": "calc", "is_required": true, "column_label": "测量3复算密度", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1106, "config_id": 13, "column_key": "density_difference", "sort_order": 20, "column_type": "calc", "is_required": true, "column_label": "最大密度差/(g/cm³)", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1107, "config_id": 13, "column_key": "mean", "sort_order": 21, "column_type": "calc", "is_required": true, "column_label": "平均密度/(g/cm³)", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1108, "config_id": 13, "column_key": "relative_deviation", "sort_order": 22, "column_type": "calc", "is_required": true, "column_label": "相对偏差/%", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1109, "config_id": 13, "column_key": "conclusion", "sort_order": 23, "column_type": "calc", "is_required": true, "column_label": "单样结论", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1110, "config_id": 13, "column_key": "data_file_no", "sort_order": 24, "column_type": "text", "is_required": true, "column_label": "数据文件编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1111, "config_id": 13, "column_key": "note", "sort_order": 25, "column_type": "text", "is_required": true, "column_label": "备注", "calc_precision": 3, "column_default": "", "calc_expression": ""}], "extra_json": {"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx", "report_decisive_photo_codes": ["DENSITY_RESULT", "DENSITY_CALIBRATION"]}, "db_mappings": [{"col_index": 1, "field_key": "attachment_ref_t10", "row_index": 4, "transform": "text", "table_index": 10, "checkbox_selection": ""}, {"col_index": 5, "field_key": "auto_calc_check", "row_index": 4, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 7, "field_key": "balance_calibration", "row_index": 0, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 3, "field_key": "declared_density", "row_index": 1, "transform": "text", "table_index": 10, "checkbox_selection": ""}, {"col_index": 1, "field_key": "declared_source", "row_index": 1, "transform": "text", "table_index": 10, "checkbox_selection": ""}, {"col_index": 1, "field_key": "density_verdict", "row_index": 3, "transform": "checkbox", "table_index": 10, "checkbox_selection": ""}, {"col_index": 3, "field_key": "overall_mean", "row_index": 7, "transform": "text", "table_index": 7, "checkbox_selection": ""}, {"col_index": 8, "field_key": "overall_mean_1dp", "row_index": 7, "transform": "text", "table_index": 7, "checkbox_selection": ""}, {"col_index": 10, "field_key": "overall_verdict", "row_index": 7, "transform": "checkbox", "table_index": 7, "checkbox_selection": ""}, {"col_index": 6, "field_key": "system_check", "row_index": 6, "transform": "checkbox", "table_index": 3, "checkbox_selection": ""}]}	0ce18035f4bf21b97975efc372fc6b22b3c35c819d099a2af30be3dacf72a6e0	2026-08-18 14:38:18.237151+08
BP20260819001-T01	2	V2.0	{"fields": [{"id": 3182, "config_id": 2, "field_key": "test_date", "is_actual": false, "field_type": "date", "sort_order": 1, "field_label": "检测日期", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3200, "config_id": 2, "field_key": "fixture_no", "is_actual": false, "field_type": "text", "sort_order": 1, "field_label": "金瓷结合试验夹具编号", "is_readonly": false, "is_required": false, "field_default": "BPGL-B009", "field_options": "", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3213, "config_id": 2, "field_key": "temperature_compliance", "is_actual": true, "field_type": "select", "sort_order": 1, "field_label": "本次温度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3201, "config_id": 2, "field_key": "support_span", "is_actual": false, "field_type": "number", "sort_order": 2, "field_label": "支承跨距/mm", "is_readonly": false, "is_required": false, "field_default": "20.0", "field_options": "", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3183, "config_id": 2, "field_key": "temperature_before", "is_actual": true, "field_type": "number", "sort_order": 2, "field_label": "检测前温度/℃", "is_readonly": false, "is_required": false, "field_default": "23.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3214, "config_id": 2, "field_key": "humidity_compliance", "is_actual": true, "field_type": "select", "sort_order": 2, "field_label": "本次湿度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3215, "config_id": 2, "field_key": "interference_compliance", "is_actual": true, "field_type": "select", "sort_order": 3, "field_label": "环境干扰控制是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3184, "config_id": 2, "field_key": "temperature_after", "is_actual": true, "field_type": "number", "sort_order": 3, "field_label": "检测后温度/℃", "is_readonly": false, "is_required": false, "field_default": "23.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3202, "config_id": 2, "field_key": "roller_radius", "is_actual": false, "field_type": "number", "sort_order": 3, "field_label": "压头/支点半径R/mm", "is_readonly": false, "is_required": false, "field_default": "1.0", "field_options": "", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3185, "config_id": 2, "field_key": "humidity_before", "is_actual": true, "field_type": "number", "sort_order": 4, "field_label": "检测前湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3216, "config_id": 2, "field_key": "work_area_condition", "is_actual": true, "field_type": "multiselect", "sort_order": 4, "field_label": "工作区域实际状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "清洁,干燥,无明显粉尘,无无关物品", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3203, "config_id": 2, "field_key": "parallel_block_no", "is_actual": false, "field_type": "text", "sort_order": 4, "field_label": "平行块编号", "is_readonly": false, "is_required": false, "field_default": "BGGL-B019", "field_options": "", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3186, "config_id": 2, "field_key": "humidity_after", "is_actual": true, "field_type": "number", "sort_order": 5, "field_label": "检测后湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3217, "config_id": 2, "field_key": "equipment_traceability_confirmation", "is_actual": true, "field_type": "select", "sort_order": 5, "field_label": "设备证书、有效期及溯源信息核对结果", "is_readonly": false, "is_required": false, "field_default": "已核对且在有效期内", "field_options": "已核对且在有效期内,存在异常", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3204, "config_id": 2, "field_key": "parallel_block_parallelism", "is_actual": true, "field_type": "number", "sort_order": 5, "field_label": "平行块平行度/mm", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3187, "config_id": 2, "field_key": "detection_location", "is_actual": false, "field_type": "text", "sort_order": 6, "field_label": "检测地点", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3205, "config_id": 2, "field_key": "loading_speed", "is_actual": false, "field_type": "number", "sort_order": 6, "field_label": "加载速度/mm/min", "is_readonly": false, "is_required": false, "field_default": "1.5", "field_options": "", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3218, "config_id": 2, "field_key": "sample_preparation_actual", "is_actual": true, "field_type": "text", "sort_order": 6, "field_label": "本次样品制备及表面状态说明", "is_readonly": false, "is_required": false, "field_default": "已按方法要求确认", "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3219, "config_id": 2, "field_key": "centering_confirmation", "is_actual": true, "field_type": "select", "sort_order": 7, "field_label": "试样居中及跨距确认", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3188, "config_id": 2, "field_key": "start_time", "is_actual": true, "field_type": "datetime", "sort_order": 7, "field_label": "实验开始时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3206, "config_id": 2, "field_key": "observation_method", "is_actual": false, "field_type": "select", "sort_order": 7, "field_label": "裂纹萌生观察方式", "is_readonly": false, "is_required": false, "field_default": "目视", "field_options": "声响,目视", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3189, "config_id": 2, "field_key": "end_time", "is_actual": true, "field_type": "datetime", "sort_order": 8, "field_label": "实验结束时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3207, "config_id": 2, "field_key": "parallel_check", "is_actual": false, "field_type": "select", "sort_order": 8, "field_label": "夹具平行与居中确认", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "符合,不符合", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3220, "config_id": 2, "field_key": "crack_observation_note", "is_actual": true, "field_type": "text", "sort_order": 8, "field_label": "裂纹萌生/陶瓷剥离观察说明", "is_readonly": false, "is_required": false, "field_default": "按声响或目视结果判定", "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3190, "config_id": 2, "field_key": "environment_interference", "is_actual": false, "field_type": "select", "sort_order": 9, "field_label": "振动/气流影响", "is_readonly": false, "is_required": false, "field_default": "无明显干扰", "field_options": "无明显干扰,有干扰", "section_order": 1, "section_title": "环境与设备"}, {"id": 3208, "config_id": 2, "field_key": "metal_name", "is_actual": false, "field_type": "text", "sort_order": 9, "field_label": "试样名称", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3191, "config_id": 2, "field_key": "work_area_status", "is_actual": false, "field_type": "multiselect", "sort_order": 10, "field_label": "试验区域状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "清洁,干燥,无明显粉尘,无无关物品", "section_order": 1, "section_title": "环境与设备"}, {"id": 3209, "config_id": 2, "field_key": "metal_batch", "is_actual": false, "field_type": "text", "sort_order": 10, "field_label": "批号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3192, "config_id": 2, "field_key": "software", "is_actual": false, "field_type": "text", "sort_order": 11, "field_label": "软件名称/版本", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3210, "config_id": 2, "field_key": "em_source", "is_actual": false, "field_type": "select", "sort_order": 11, "field_label": "杨氏模量来源", "is_readonly": false, "is_required": false, "field_default": "说明书", "field_options": "说明书,检测报告,注册资料,质保书,其他", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3211, "config_id": 2, "field_key": "em_source_file", "is_actual": false, "field_type": "text", "sort_order": 12, "field_label": "杨氏模量来源文件编号", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3193, "config_id": 2, "field_key": "data_path", "is_actual": false, "field_type": "text", "sort_order": 12, "field_label": "仪器原始数据保存路径", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3194, "config_id": 2, "field_key": "equipment_name", "is_actual": false, "field_type": "text", "sort_order": 13, "field_label": "主要设备名称", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3212, "config_id": 2, "field_key": "orientation", "is_actual": false, "field_type": "select", "sort_order": 13, "field_label": "试样放置方向", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "金属面朝上、陶瓷面朝下,其他", "section_order": 2, "section_title": "裂纹萌生试验参数"}, {"id": 3195, "config_id": 2, "field_key": "equipment_model", "is_actual": false, "field_type": "text", "sort_order": 14, "field_label": "设备型号/规格", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3196, "config_id": 2, "field_key": "equipment_no", "is_actual": false, "field_type": "text", "sort_order": 15, "field_label": "设备管理编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3197, "config_id": 2, "field_key": "calibration_certificate", "is_actual": false, "field_type": "text", "sort_order": 16, "field_label": "校准/检定证书编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3198, "config_id": 2, "field_key": "calibration_due", "is_actual": false, "field_type": "text", "sort_order": 17, "field_label": "台账校准时间", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3199, "config_id": 2, "field_key": "equipment_status", "is_actual": false, "field_type": "select", "sort_order": 18, "field_label": "使用前设备状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "正常,异常", "section_order": 1, "section_title": "环境与设备"}], "columns": [{"id": 939, "config_id": 2, "column_key": "sample_no", "sort_order": 1, "column_type": "text", "is_required": true, "column_label": "试样编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 940, "config_id": 2, "column_key": "width", "sort_order": 2, "column_type": "number", "is_required": true, "column_label": "宽度/mm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 941, "config_id": 2, "column_key": "dm1", "sort_order": 3, "column_type": "number", "is_required": true, "column_label": "金属厚度1/mm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 942, "config_id": 2, "column_key": "dm2", "sort_order": 4, "column_type": "number", "is_required": true, "column_label": "金属厚度2/mm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 943, "config_id": 2, "column_key": "dm3", "sort_order": 5, "column_type": "number", "is_required": true, "column_label": "金属厚度3/mm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 944, "config_id": 2, "column_key": "dm_mean", "sort_order": 6, "column_type": "calc", "is_required": true, "column_label": "金属厚度平均/mm", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"dm_mean\\", \\"op\\": \\"avg\\", \\"inputs\\": [\\"dm1\\", \\"dm2\\", \\"dm3\\"], \\"args\\": {\\"precision\\": 4}}"}, {"id": 945, "config_id": 2, "column_key": "em", "sort_order": 7, "column_type": "number", "is_required": true, "column_label": "金属弹性模量/GPa", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 946, "config_id": 2, "column_key": "k", "sort_order": 8, "column_type": "number", "is_required": true, "column_label": "K/mm⁻²", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 947, "config_id": 2, "column_key": "ffail", "sort_order": 9, "column_type": "number", "is_required": true, "column_label": "裂纹萌生力/N", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 948, "config_id": 2, "column_key": "tau", "sort_order": 10, "column_type": "calc", "is_required": true, "column_label": "结合强度/MPa", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"tau\\", \\"op\\": \\"multiply\\", \\"inputs\\": [\\"k\\", \\"ffail\\"], \\"args\\": {\\"precision\\": 2}}"}, {"id": 949, "config_id": 2, "column_key": "crack_position", "sort_order": 11, "column_type": "text", "is_required": true, "column_label": "开裂位置", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 950, "config_id": 2, "column_key": "failure_mode", "sort_order": 12, "column_type": "text", "is_required": true, "column_label": "断裂/剥离形态", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 951, "config_id": 2, "column_key": "curve_no", "sort_order": 13, "column_type": "text", "is_required": true, "column_label": "曲线/数据文件编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 952, "config_id": 2, "column_key": "conclusion", "sort_order": 14, "column_type": "calc", "is_required": true, "column_label": "单样结论", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"conclusion\\", \\"op\\": \\"gt\\", \\"inputs\\": [\\"tau\\"], \\"args\\": {\\"constant\\": 25, \\"true_value\\": \\"符合\\", \\"false_value\\": \\"不符合\\"}}"}, {"id": 953, "config_id": 2, "column_key": "note", "sort_order": 15, "column_type": "text", "is_required": true, "column_label": "备注", "calc_precision": 3, "column_default": "", "calc_expression": ""}], "extra_json": {"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R004_MC_CRACK.docx", "report_decisive_photo_codes": ["MC_K_VALUE", "MC_REPORT"]}, "db_mappings": []}	fde574f3e17e19e648df80a643225616e354d65ec450839d0373a03b4dc1b3e0	2026-08-19 10:36:08.049823+08
BP20260819005-T01	3	V2.0	{"fields": [{"id": 3240, "config_id": 3, "field_key": "radiation_safety", "is_actual": false, "field_type": "select", "sort_order": 1, "field_label": "辐射安全确认", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "允许曝光,禁止曝光", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3222, "config_id": 3, "field_key": "test_date", "is_actual": false, "field_type": "date", "sort_order": 1, "field_label": "检测日期", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3288, "config_id": 3, "field_key": "temperature_compliance", "is_actual": true, "field_type": "select", "sort_order": 1, "field_label": "本次温度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3241, "config_id": 3, "field_key": "xray_model", "is_actual": false, "field_type": "text", "sort_order": 2, "field_label": "X射线机型号/编号", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3289, "config_id": 3, "field_key": "humidity_compliance", "is_actual": true, "field_type": "select", "sort_order": 2, "field_label": "本次湿度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3223, "config_id": 3, "field_key": "temperature_before", "is_actual": true, "field_type": "number", "sort_order": 2, "field_label": "检测前温度/℃", "is_readonly": false, "is_required": false, "field_default": "23.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3224, "config_id": 3, "field_key": "temperature_after", "is_actual": true, "field_type": "number", "sort_order": 3, "field_label": "检测后温度/℃", "is_readonly": false, "is_required": false, "field_default": "23.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3242, "config_id": 3, "field_key": "panel_no", "is_actual": false, "field_type": "text", "sort_order": 3, "field_label": "数据采集板编号", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3290, "config_id": 3, "field_key": "interference_compliance", "is_actual": true, "field_type": "select", "sort_order": 3, "field_label": "环境干扰控制是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3291, "config_id": 3, "field_key": "work_area_condition", "is_actual": true, "field_type": "multiselect", "sort_order": 4, "field_label": "工作区域实际状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "清洁,干燥,无明显粉尘,无无关物品", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3225, "config_id": 3, "field_key": "humidity_before", "is_actual": true, "field_type": "number", "sort_order": 4, "field_label": "检测前湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3243, "config_id": 3, "field_key": "iqi_no", "is_actual": false, "field_type": "text", "sort_order": 4, "field_label": "孔形像质计编号", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3226, "config_id": 3, "field_key": "humidity_after", "is_actual": true, "field_type": "number", "sort_order": 5, "field_label": "检测后湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50.0", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3292, "config_id": 3, "field_key": "equipment_traceability_confirmation", "is_actual": true, "field_type": "select", "sort_order": 5, "field_label": "设备证书、有效期及溯源信息核对结果", "is_readonly": false, "is_required": false, "field_default": "已核对且在有效期内", "field_options": "已核对且在有效期内,存在异常", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3244, "config_id": 3, "field_key": "density_meter_no", "is_actual": false, "field_type": "text", "sort_order": 5, "field_label": "密度计/标准密度片编号", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3227, "config_id": 3, "field_key": "detection_location", "is_actual": false, "field_type": "text", "sort_order": 6, "field_label": "检测地点", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3221, "config_id": 3, "field_key": "sample_production_date", "is_actual": false, "field_type": "text", "sort_order": 6, "field_label": "样品生产日期/批次日期", "is_readonly": true, "is_required": false, "field_default": null, "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3245, "config_id": 3, "field_key": "density_nominal", "is_actual": true, "field_type": "number", "sort_order": 6, "field_label": "标准密度片标称值", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3228, "config_id": 3, "field_key": "start_time", "is_actual": true, "field_type": "datetime", "sort_order": 7, "field_label": "实验开始时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3293, "config_id": 3, "field_key": "sample_preparation_actual", "is_actual": true, "field_type": "text", "sort_order": 7, "field_label": "本次样品制备及表面状态说明", "is_readonly": false, "is_required": false, "field_default": "已按方法要求确认", "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3246, "config_id": 3, "field_key": "density_measured_1", "is_actual": true, "field_type": "number", "sort_order": 7, "field_label": "标准密度片实测值1", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3229, "config_id": 3, "field_key": "end_time", "is_actual": true, "field_type": "datetime", "sort_order": 8, "field_label": "实验结束时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3294, "config_id": 3, "field_key": "method_execution_confirmation", "is_actual": true, "field_type": "select", "sort_order": 8, "field_label": "本次操作与受控方法一致性", "is_readonly": false, "is_required": false, "field_default": "一致", "field_options": "一致,存在偏离", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3247, "config_id": 3, "field_key": "density_measured_2", "is_actual": true, "field_type": "number", "sort_order": 8, "field_label": "标准密度片实测值2", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3230, "config_id": 3, "field_key": "environment_interference", "is_actual": false, "field_type": "select", "sort_order": 9, "field_label": "振动/气流影响", "is_readonly": false, "is_required": false, "field_default": "无明显干扰", "field_options": "无明显干扰,有干扰", "section_order": 1, "section_title": "环境与设备"}, {"id": 3248, "config_id": 3, "field_key": "density_measured_3", "is_actual": true, "field_type": "number", "sort_order": 9, "field_label": "标准密度片实测值3", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3295, "config_id": 3, "field_key": "sample_surface_xray", "is_actual": true, "field_type": "select", "sort_order": 9, "field_label": "样品表面清洁、干燥状态", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3231, "config_id": 3, "field_key": "work_area_status", "is_actual": false, "field_type": "multiselect", "sort_order": 10, "field_label": "试验区域状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "清洁,干燥,无明显粉尘,无无关物品", "section_order": 1, "section_title": "环境与设备"}, {"id": 3249, "config_id": 3, "field_key": "tube_voltage", "is_actual": false, "field_type": "number", "sort_order": 10, "field_label": "管电压/kV", "is_readonly": false, "is_required": false, "field_default": "75.0", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3296, "config_id": 3, "field_key": "radiation_zone_clear", "is_actual": true, "field_type": "select", "sort_order": 10, "field_label": "辐射区域无无关人员及物品", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3232, "config_id": 3, "field_key": "software", "is_actual": false, "field_type": "text", "sort_order": 11, "field_label": "软件名称/版本", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3297, "config_id": 3, "field_key": "panel_iqi_position_confirmation", "is_actual": true, "field_type": "select", "sort_order": 11, "field_label": "探测板、像质计与样品位置确认", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "符合,不符合", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3250, "config_id": 3, "field_key": "tube_current", "is_actual": false, "field_type": "number", "sort_order": 11, "field_label": "管电流/mA", "is_readonly": false, "is_required": false, "field_default": "56.0", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3251, "config_id": 3, "field_key": "exposure_time", "is_actual": false, "field_type": "number", "sort_order": 12, "field_label": "曝光时间/ms", "is_readonly": false, "is_required": false, "field_default": "110.0", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3298, "config_id": 3, "field_key": "operator_authorization", "is_actual": true, "field_type": "select", "sort_order": 12, "field_label": "X射线操作授权确认", "is_readonly": false, "is_required": false, "field_default": "已授权", "field_options": "已授权,未授权", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3233, "config_id": 3, "field_key": "data_path", "is_actual": false, "field_type": "text", "sort_order": 12, "field_label": "仪器原始数据保存路径", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3299, "config_id": 3, "field_key": "density_control_note", "is_actual": true, "field_type": "text", "sort_order": 13, "field_label": "密度/灰度标准控制范围及核查说明", "is_readonly": false, "is_required": false, "field_default": "核查结果在受控范围内", "field_options": "", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 3234, "config_id": 3, "field_key": "equipment_name", "is_actual": false, "field_type": "text", "sort_order": 13, "field_label": "主要设备名称", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3252, "config_id": 3, "field_key": "mas", "is_actual": false, "field_type": "number", "sort_order": 13, "field_label": "管电流时间积/mAs", "is_readonly": false, "is_required": false, "field_default": "6.3", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3253, "config_id": 3, "field_key": "focus_mode", "is_actual": false, "field_type": "text", "sort_order": 14, "field_label": "焦点模式", "is_readonly": false, "is_required": false, "field_default": "L", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3235, "config_id": 3, "field_key": "equipment_model", "is_actual": false, "field_type": "text", "sort_order": 14, "field_label": "设备型号/规格", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3236, "config_id": 3, "field_key": "equipment_no", "is_actual": false, "field_type": "text", "sort_order": 15, "field_label": "设备管理编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3254, "config_id": 3, "field_key": "orientation", "is_actual": false, "field_type": "text", "sort_order": 15, "field_label": "样品摆放方向", "is_readonly": false, "is_required": false, "field_default": "咬合面朝下", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3255, "config_id": 3, "field_key": "exposure_count", "is_actual": false, "field_type": "number", "sort_order": 16, "field_label": "曝光次数", "is_readonly": false, "is_required": false, "field_default": "1.0", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3237, "config_id": 3, "field_key": "calibration_certificate", "is_actual": false, "field_type": "text", "sort_order": 16, "field_label": "校准/检定证书编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3238, "config_id": 3, "field_key": "calibration_due", "is_actual": false, "field_type": "text", "sort_order": 17, "field_label": "台账校准时间", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "", "section_order": 1, "section_title": "环境与设备"}, {"id": 3256, "config_id": 3, "field_key": "parameter_adjustment", "is_actual": false, "field_type": "select", "sort_order": 17, "field_label": "参数调整情况", "is_readonly": false, "is_required": false, "field_default": "无调整", "field_options": "无调整,有调整", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3239, "config_id": 3, "field_key": "equipment_status", "is_actual": false, "field_type": "select", "sort_order": 18, "field_label": "使用前设备状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "正常,异常", "section_order": 1, "section_title": "环境与设备"}, {"id": 3257, "config_id": 3, "field_key": "iqi_gray_01_1", "is_actual": true, "field_type": "number", "sort_order": 18, "field_label": "像质计0.1 mm灰度·第1次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3258, "config_id": 3, "field_key": "iqi_gray_01_2", "is_actual": true, "field_type": "number", "sort_order": 19, "field_label": "像质计0.1 mm灰度·第2次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3259, "config_id": 3, "field_key": "iqi_gray_01_3", "is_actual": true, "field_type": "number", "sort_order": 20, "field_label": "像质计0.1 mm灰度·第3次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3260, "config_id": 3, "field_key": "iqi_gray_02_1", "is_actual": true, "field_type": "number", "sort_order": 21, "field_label": "像质计0.2 mm灰度·第1次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3261, "config_id": 3, "field_key": "iqi_gray_02_2", "is_actual": true, "field_type": "number", "sort_order": 22, "field_label": "像质计0.2 mm灰度·第2次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3262, "config_id": 3, "field_key": "iqi_gray_02_3", "is_actual": true, "field_type": "number", "sort_order": 23, "field_label": "像质计0.2 mm灰度·第3次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3263, "config_id": 3, "field_key": "iqi_gray_03_1", "is_actual": true, "field_type": "number", "sort_order": 24, "field_label": "像质计0.3 mm灰度·第1次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3264, "config_id": 3, "field_key": "iqi_gray_03_2", "is_actual": true, "field_type": "number", "sort_order": 25, "field_label": "像质计0.3 mm灰度·第2次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3265, "config_id": 3, "field_key": "iqi_gray_03_3", "is_actual": true, "field_type": "number", "sort_order": 26, "field_label": "像质计0.3 mm灰度·第3次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3266, "config_id": 3, "field_key": "iqi_gray_04_1", "is_actual": true, "field_type": "number", "sort_order": 27, "field_label": "像质计0.4 mm灰度·第1次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3267, "config_id": 3, "field_key": "iqi_gray_04_2", "is_actual": true, "field_type": "number", "sort_order": 28, "field_label": "像质计0.4 mm灰度·第2次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3268, "config_id": 3, "field_key": "iqi_gray_04_3", "is_actual": true, "field_type": "number", "sort_order": 29, "field_label": "像质计0.4 mm灰度·第3次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3269, "config_id": 3, "field_key": "iqi_gray_05_1", "is_actual": true, "field_type": "number", "sort_order": 30, "field_label": "像质计0.5 mm灰度·第1次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3270, "config_id": 3, "field_key": "iqi_gray_05_2", "is_actual": true, "field_type": "number", "sort_order": 31, "field_label": "像质计0.5 mm灰度·第2次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3271, "config_id": 3, "field_key": "iqi_gray_05_3", "is_actual": true, "field_type": "number", "sort_order": 32, "field_label": "像质计0.5 mm灰度·第3次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3272, "config_id": 3, "field_key": "iqi_gray_06_1", "is_actual": true, "field_type": "number", "sort_order": 33, "field_label": "像质计0.6 mm灰度·第1次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3273, "config_id": 3, "field_key": "iqi_gray_06_2", "is_actual": true, "field_type": "number", "sort_order": 34, "field_label": "像质计0.6 mm灰度·第2次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3274, "config_id": 3, "field_key": "iqi_gray_06_3", "is_actual": true, "field_type": "number", "sort_order": 35, "field_label": "像质计0.6 mm灰度·第3次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3275, "config_id": 3, "field_key": "iqi_gray_07_1", "is_actual": true, "field_type": "number", "sort_order": 36, "field_label": "像质计0.7 mm灰度·第1次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3276, "config_id": 3, "field_key": "iqi_gray_07_2", "is_actual": true, "field_type": "number", "sort_order": 37, "field_label": "像质计0.7 mm灰度·第2次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3277, "config_id": 3, "field_key": "iqi_gray_07_3", "is_actual": true, "field_type": "number", "sort_order": 38, "field_label": "像质计0.7 mm灰度·第3次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3278, "config_id": 3, "field_key": "iqi_gray_08_1", "is_actual": true, "field_type": "number", "sort_order": 39, "field_label": "像质计0.8 mm灰度·第1次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3279, "config_id": 3, "field_key": "iqi_gray_08_2", "is_actual": true, "field_type": "number", "sort_order": 40, "field_label": "像质计0.8 mm灰度·第2次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3280, "config_id": 3, "field_key": "iqi_gray_08_3", "is_actual": true, "field_type": "number", "sort_order": 41, "field_label": "像质计0.8 mm灰度·第3次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3281, "config_id": 3, "field_key": "iqi_gray_09_1", "is_actual": true, "field_type": "number", "sort_order": 42, "field_label": "像质计0.9 mm灰度·第1次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3282, "config_id": 3, "field_key": "iqi_gray_09_2", "is_actual": true, "field_type": "number", "sort_order": 43, "field_label": "像质计0.9 mm灰度·第2次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3283, "config_id": 3, "field_key": "iqi_gray_09_3", "is_actual": true, "field_type": "number", "sort_order": 44, "field_label": "像质计0.9 mm灰度·第3次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3284, "config_id": 3, "field_key": "iqi_gray_10_1", "is_actual": true, "field_type": "number", "sort_order": 45, "field_label": "像质计1.0 mm灰度·第1次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3285, "config_id": 3, "field_key": "iqi_gray_10_2", "is_actual": true, "field_type": "number", "sort_order": 46, "field_label": "像质计1.0 mm灰度·第2次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3286, "config_id": 3, "field_key": "iqi_gray_10_3", "is_actual": true, "field_type": "number", "sort_order": 47, "field_label": "像质计1.0 mm灰度·第3次", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}, {"id": 3287, "config_id": 3, "field_key": "image_path", "is_actual": false, "field_type": "text", "sort_order": 48, "field_label": "原始图像保存路径", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "", "section_order": 2, "section_title": "辐射安全与曝光参数"}], "columns": [{"id": 954, "config_id": 3, "column_key": "sample_no", "sort_order": 1, "column_type": "text", "is_required": true, "column_label": "样品编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 955, "config_id": 3, "column_key": "sample_name_tooth", "sort_order": 2, "column_type": "text", "is_required": true, "column_label": "样品名称/牙位", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 956, "config_id": 3, "column_key": "image_no", "sort_order": 3, "column_type": "text", "is_required": true, "column_label": "图像文件编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 957, "config_id": 3, "column_key": "sample_status", "sort_order": 4, "column_type": "select", "is_required": true, "column_label": "样品状态", "calc_precision": 3, "column_default": "完好|异常", "calc_expression": ""}, {"id": 958, "config_id": 3, "column_key": "image_valid", "sort_order": 5, "column_type": "select", "is_required": true, "column_label": "图像有效性", "calc_precision": 3, "column_default": "有效|无效", "calc_expression": ""}, {"id": 959, "config_id": 3, "column_key": "iqi_display", "sort_order": 6, "column_type": "select", "is_required": true, "column_label": "像质计显示", "calc_precision": 3, "column_default": "清晰|不清晰", "calc_expression": ""}, {"id": 960, "config_id": 3, "column_key": "roi1_reading1", "sort_order": 7, "column_type": "number", "is_required": true, "column_label": "ROI-1灰度·第1次", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 961, "config_id": 3, "column_key": "roi1_reading2", "sort_order": 8, "column_type": "number", "is_required": true, "column_label": "ROI-1灰度·第2次", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 962, "config_id": 3, "column_key": "roi1_reading3", "sort_order": 9, "column_type": "number", "is_required": true, "column_label": "ROI-1灰度·第3次", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 963, "config_id": 3, "column_key": "roi2_reading1", "sort_order": 10, "column_type": "number", "is_required": true, "column_label": "ROI-2灰度·第1次", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 964, "config_id": 3, "column_key": "roi2_reading2", "sort_order": 11, "column_type": "number", "is_required": true, "column_label": "ROI-2灰度·第2次", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 965, "config_id": 3, "column_key": "roi2_reading3", "sort_order": 12, "column_type": "number", "is_required": true, "column_label": "ROI-2灰度·第3次", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 966, "config_id": 3, "column_key": "roi3_reading1", "sort_order": 13, "column_type": "number", "is_required": true, "column_label": "ROI-3灰度·第1次", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 967, "config_id": 3, "column_key": "roi3_reading2", "sort_order": 14, "column_type": "number", "is_required": true, "column_label": "ROI-3灰度·第2次", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 968, "config_id": 3, "column_key": "roi3_reading3", "sort_order": 15, "column_type": "number", "is_required": true, "column_label": "ROI-3灰度·第3次", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 969, "config_id": 3, "column_key": "roi1", "sort_order": 16, "column_type": "calc", "is_required": true, "column_label": "ROI-1平均灰度", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"roi1\\", \\"op\\": \\"avg\\", \\"inputs\\": [\\"roi1_reading1\\", \\"roi1_reading2\\", \\"roi1_reading3\\"], \\"args\\": {\\"precision\\": 2}}"}, {"id": 970, "config_id": 3, "column_key": "roi2", "sort_order": 17, "column_type": "calc", "is_required": true, "column_label": "ROI-2平均灰度", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"roi2\\", \\"op\\": \\"avg\\", \\"inputs\\": [\\"roi2_reading1\\", \\"roi2_reading2\\", \\"roi2_reading3\\"], \\"args\\": {\\"precision\\": 2}}"}, {"id": 971, "config_id": 3, "column_key": "roi3", "sort_order": 18, "column_type": "calc", "is_required": true, "column_label": "ROI-3平均灰度", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"roi3\\", \\"op\\": \\"avg\\", \\"inputs\\": [\\"roi3_reading1\\", \\"roi3_reading2\\", \\"roi3_reading3\\"], \\"args\\": {\\"precision\\": 2}}"}, {"id": 972, "config_id": 3, "column_key": "roi_mean", "sort_order": 19, "column_type": "calc", "is_required": true, "column_label": "ROI平均灰度", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\": \\"roi_mean\\", \\"op\\": \\"avg\\", \\"inputs\\": [\\"roi1\\", \\"roi2\\", \\"roi3\\"], \\"args\\": {\\"precision\\": 2}}"}, {"id": 973, "config_id": 3, "column_key": "thickness_relation", "sort_order": 20, "column_type": "text", "is_required": true, "column_label": "接近/介于像质计厚度点", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 974, "config_id": 3, "column_key": "estimated_thickness", "sort_order": 21, "column_type": "text", "is_required": true, "column_label": "厚度估算结果", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 975, "config_id": 3, "column_key": "defect", "sort_order": 22, "column_type": "text", "is_required": true, "column_label": "异常影像/位置", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 976, "config_id": 3, "column_key": "retake", "sort_order": 23, "column_type": "select", "is_required": true, "column_label": "是否复拍", "calc_precision": 3, "column_default": "否|是", "calc_expression": ""}, {"id": 977, "config_id": 3, "column_key": "conclusion", "sort_order": 24, "column_type": "select", "is_required": true, "column_label": "单样结论", "calc_precision": 3, "column_default": "合格|不合格|需复检|超出适用范围", "calc_expression": ""}, {"id": 978, "config_id": 3, "column_key": "note", "sort_order": 25, "column_type": "text", "is_required": true, "column_label": "备注", "calc_precision": 3, "column_default": "", "calc_expression": ""}], "extra_json": {"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1.0, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R005_XRAY.docx", "report_decisive_photo_codes": ["RADIOGRAPH", "ROI"]}, "db_mappings": [{"col_index": 5, "field_key": "density_mean", "row_index": 1, "transform": "text", "table_index": 4, "checkbox_selection": ""}, {"col_index": 7, "field_key": "density_verdict", "row_index": 1, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "end_time", "row_index": 0, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 1, "field_key": "humidity_before", "row_index": 2, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 5, "field_key": "humidity_ok", "row_index": 2, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 6, "field_key": "image_no_t7", "row_index": 0, "transform": "text", "table_index": 7, "checkbox_selection": ""}, {"col_index": 5, "field_key": "operator_t2", "row_index": 0, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 6, "field_key": "operator_t7", "row_index": 1, "transform": "text", "table_index": 7, "checkbox_selection": ""}, {"col_index": 10, "field_key": "reviewer_t7", "row_index": 1, "transform": "text", "table_index": 7, "checkbox_selection": ""}, {"col_index": 2, "field_key": "sample_no_t7", "row_index": 0, "transform": "text", "table_index": 7, "checkbox_selection": ""}, {"col_index": 2, "field_key": "software", "row_index": 1, "transform": "text", "table_index": 7, "checkbox_selection": ""}, {"col_index": 1, "field_key": "start_time", "row_index": 0, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 1, "field_key": "temperature_before", "row_index": 1, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 5, "field_key": "temperature_ok", "row_index": 1, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 10, "field_key": "test_date", "row_index": 0, "transform": "text", "table_index": 7, "checkbox_selection": ""}]}	0925996e6710146d75e503fcf27b52f28e351f78b7edc177125588acaef523a6	2026-08-19 11:01:59.097779+08
BP20260819006-T01	1	V2.0	{"fields": [{"id": 4133, "config_id": 1, "field_key": "test_date", "is_actual": false, "field_type": "date", "sort_order": 0, "field_label": "检测日期", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4134, "config_id": 1, "field_key": "standard_block", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "标准粗糙度样板编号", "is_readonly": false, "is_required": false, "field_default": "BPGL-B001", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4135, "config_id": 1, "field_key": "temperature_before", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "本次温度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4136, "config_id": 1, "field_key": "humidity_before", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "本次湿度条件是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4137, "config_id": 1, "field_key": "temperature_before", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测前温度/℃", "is_readonly": false, "is_required": false, "field_default": "23", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4138, "config_id": 1, "field_key": "standard_block_nominal", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "标准样板标称值/μm", "is_readonly": false, "is_required": false, "field_default": "1.61", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4139, "config_id": 1, "field_key": "repeat_check_1", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "标准样板实测值1/μm", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4140, "config_id": 1, "field_key": "temperature_after", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测后温度/℃", "is_readonly": false, "is_required": false, "field_default": "23", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4141, "config_id": 1, "field_key": "interference_compliance", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "环境干扰控制是否符合", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4142, "config_id": 1, "field_key": "humidity_before", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测前湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4143, "config_id": 1, "field_key": "work_area_condition", "is_actual": false, "field_type": "multiselect", "sort_order": 0, "field_label": "工作区域实际状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "[\\"清洁\\",\\"干燥\\",\\"无明显粉尘\\",\\"无无关物品\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4144, "config_id": 1, "field_key": "equipment_traceability_confirmation", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "设备证书、有效期及溯源信息核对结果", "is_readonly": false, "is_required": false, "field_default": "已核对且在有效期内", "field_options": "[\\"已核对且在有效期内\\",\\"存在异常\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4145, "config_id": 1, "field_key": "humidity_before", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "检测后湿度/%RH", "is_readonly": false, "is_required": false, "field_default": "50", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4146, "config_id": 1, "field_key": "repeat_check_3", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "标准样板实测值3/μm", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4147, "config_id": 1, "field_key": "detection_location", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "检测地点", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4148, "config_id": 1, "field_key": "sample_production_date", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "样品生产日期/批次日期", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4149, "config_id": 1, "field_key": "standard_block_result", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "标准样板核查结果", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[\\"合格\\",\\"不合格\\"]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4150, "config_id": 1, "field_key": "calculation_standard", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "计算标准", "is_readonly": false, "is_required": false, "field_default": "ISO-97", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4151, "config_id": 1, "field_key": "start_time", "is_actual": false, "field_type": "datetime", "sort_order": 0, "field_label": "实验开始时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4152, "config_id": 1, "field_key": "sample_preparation_actual", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "本次样品制备及表面状态说明", "is_readonly": false, "is_required": false, "field_default": "已按方法要求确认", "field_options": "[]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4153, "config_id": 1, "field_key": "method_execution_confirmation", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "本次操作与受控方法一致性", "is_readonly": false, "is_required": false, "field_default": "一致", "field_options": "[\\"一致\\",\\"存在偏离\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4154, "config_id": 1, "field_key": "end_time", "is_actual": false, "field_type": "datetime", "sort_order": 0, "field_label": "实验结束时间", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4155, "config_id": 1, "field_key": "shape_removal", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "形状去除", "is_readonly": false, "is_required": false, "field_default": "自动", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4156, "config_id": 1, "field_key": "filter_type", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "滤波器", "is_readonly": false, "is_required": false, "field_default": "高斯", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4157, "config_id": 1, "field_key": "z_axis_marking", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "Z轴正方向标识", "is_readonly": false, "is_required": false, "field_default": "清晰", "field_options": "[\\"清晰\\",\\"不清晰\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4158, "config_id": 1, "field_key": "environment_interference", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "振动/气流影响", "is_readonly": false, "is_required": false, "field_default": "无明显干扰", "field_options": "[\\"无明显干扰\\",\\"有干扰\\"]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4159, "config_id": 1, "field_key": "surface_cleaning_actual", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "测试面清洁状态", "is_readonly": false, "is_required": false, "field_default": "清洁", "field_options": "[\\"清洁\\",\\"不清洁\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4160, "config_id": 1, "field_key": "lambda_s", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "λs", "is_readonly": false, "is_required": false, "field_default": "自动", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4161, "config_id": 1, "field_key": "work_area_status", "is_actual": false, "field_type": "multiselect", "sort_order": 0, "field_label": "试验区域状态", "is_readonly": false, "is_required": false, "field_default": "清洁,干燥,无明显粉尘,无无关物品", "field_options": "[\\"清洁\\",\\"干燥\\",\\"无明显粉尘\\",\\"无无关物品\\"]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4162, "config_id": 1, "field_key": "fixture_stability", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "试样固定及工作台稳定性", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4163, "config_id": 1, "field_key": "software", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "软件名称/版本", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4164, "config_id": 1, "field_key": "measurement_range", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "测量范围/μm", "is_readonly": false, "is_required": false, "field_default": "40", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4165, "config_id": 1, "field_key": "measurement_line_note", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "实际测量线/方向说明", "is_readonly": false, "is_required": false, "field_default": "按受控方法规定位置测量", "field_options": "[]", "section_order": 3, "section_title": "母版补充现场观察"}, {"id": 4166, "config_id": 1, "field_key": "sampling_length", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "取样长度/mm", "is_readonly": false, "is_required": false, "field_default": "2.5", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4167, "config_id": 1, "field_key": "data_path", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "仪器原始数据保存路径", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4168, "config_id": 1, "field_key": "sampling_count", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "取样个数", "is_readonly": false, "is_required": false, "field_default": "3", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4169, "config_id": 1, "field_key": "equipment_name", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "主要设备名称", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4170, "config_id": 1, "field_key": "equipment_model", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "设备型号/规格", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4171, "config_id": 1, "field_key": "evaluation_length", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "评定长度/mm", "is_readonly": false, "is_required": false, "field_default": "7.5", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4172, "config_id": 1, "field_key": "measuring_speed", "is_actual": false, "field_type": "number", "sort_order": 0, "field_label": "测量速度/mm/s", "is_readonly": false, "is_required": false, "field_default": "1", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4173, "config_id": 1, "field_key": "equipment_no", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "设备管理编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4174, "config_id": 1, "field_key": "calibration_certificate", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "校准/检定证书编号", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4175, "config_id": 1, "field_key": "cutoff_filter", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "滤波/计算标准", "is_readonly": false, "is_required": false, "field_default": "高斯", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4176, "config_id": 1, "field_key": "calibration_due", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "台账校准时间", "is_readonly": true, "is_required": false, "field_default": "", "field_options": "[]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4177, "config_id": 1, "field_key": "equipment_status", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "使用前设备状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[\\"正常\\",\\"异常\\"]", "section_order": 1, "section_title": "环境与设备"}, {"id": 4178, "config_id": 1, "field_key": "platform_level", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "工作台水平状态", "is_readonly": false, "is_required": false, "field_default": "符合", "field_options": "[\\"符合\\",\\"不符合\\"]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4179, "config_id": 1, "field_key": "surface_state", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "试样表面状态", "is_readonly": false, "is_required": false, "field_default": "", "field_options": "[\\"原打印表面\\",\\"经处理表面\\",\\"其他\\"]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4180, "config_id": 1, "field_key": "measurement_direction", "is_actual": false, "field_type": "text", "sort_order": 0, "field_label": "测量方向/线位", "is_readonly": false, "is_required": false, "field_default": "3条平行、不重叠、代表性测量线", "field_options": "[]", "section_order": 2, "section_title": "试验参数与使用前确认"}, {"id": 4181, "config_id": 1, "field_key": "three_length_mode", "is_actual": false, "field_type": "select", "sort_order": 0, "field_label": "评定长度方式", "is_readonly": true, "is_required": false, "field_default": "3L（默认）", "field_options": "[\\"5L（默认）\\",\\"3L（已完成方法确认）\\"]", "section_order": 2, "section_title": "试验参数与使用前确认"}], "columns": [{"id": 1195, "config_id": 1, "column_key": "sample_no", "sort_order": 0, "column_type": "text", "is_required": false, "column_label": "试样编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1196, "config_id": 1, "column_key": "surface_confirm", "sort_order": 1, "column_type": "select:符合|不符合", "is_required": false, "column_label": "原打印面/方向确认", "calc_precision": 3, "column_default": "符合", "calc_expression": ""}, {"id": 1197, "config_id": 1, "column_key": "position", "sort_order": 2, "column_type": "text", "is_required": false, "column_label": "测量位置", "calc_precision": 3, "column_default": "Z轴", "calc_expression": ""}, {"id": 1198, "config_id": 1, "column_key": "ra1", "sort_order": 3, "column_type": "number", "is_required": false, "column_label": "Ra1/μm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1199, "config_id": 1, "column_key": "ra2", "sort_order": 4, "column_type": "number", "is_required": false, "column_label": "Ra2/μm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1200, "config_id": 1, "column_key": "ra3", "sort_order": 5, "column_type": "number", "is_required": false, "column_label": "Ra3/μm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1201, "config_id": 1, "column_key": "mean", "sort_order": 6, "column_type": "calc", "is_required": false, "column_label": "平均值/μm", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\":\\"mean\\",\\"op\\":\\"avg\\",\\"inputs\\":[\\"ra1\\",\\"ra2\\",\\"ra3\\"],\\"args\\":{\\"precision\\":3}}"}, {"id": 1202, "config_id": 1, "column_key": "limit", "sort_order": 7, "column_type": "number", "is_required": false, "column_label": "判定限值/μm", "calc_precision": 3, "column_default": "15", "calc_expression": ""}, {"id": 1203, "config_id": 1, "column_key": "conclusion", "sort_order": 8, "column_type": "calc", "is_required": false, "column_label": "单样结论", "calc_precision": 3, "column_default": "", "calc_expression": "{\\"column_key\\":\\"conclusion\\",\\"op\\":\\"le\\",\\"inputs\\":[\\"mean\\",\\"limit\\"],\\"args\\":{\\"constant\\":15,\\"true_value\\":\\"符合\\",\\"false_value\\":\\"不符合\\"}}"}, {"id": 1204, "config_id": 1, "column_key": "retest_mean", "sort_order": 9, "column_type": "number", "is_required": false, "column_label": "复测后平均/μm", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1205, "config_id": 1, "column_key": "file_no", "sort_order": 10, "column_type": "text", "is_required": false, "column_label": "曲线/数据文件编号", "calc_precision": 3, "column_default": "", "calc_expression": ""}, {"id": 1206, "config_id": 1, "column_key": "note", "sort_order": 11, "column_type": "text", "is_required": false, "column_label": "备注", "calc_precision": 3, "column_default": "", "calc_expression": ""}], "extra_json": {"constants": {"devices": {"fixture_no": "BPGL-B009", "d65_lightbox": "D65灯箱", "tarnish_eq_a": "BPGL-A025", "tarnish_eq_b": "BPGL-C006", "parallel_block_no": "BGGL-B019", "roughness_instrument": "BPGL-B002"}, "fixed_text": {"tarnish_bath_volume_ml": 1000}, "thresholds": {"crack_span_mm": 20, "rough_limit_um": 15, "crack_roller_mm": 1, "density_tol_pct": 5, "crack_block_spec": "（30×6×5） mm", "thickness_tol_mm": 0.05, "fixed_denture_ra_um": 0.025}}, "camera_hints": {"ENV": "拍摄温湿度表/环境监控屏，包含日期、时间、温湿度读数", "ROI": "拍摄ROI框选位置及对应的灰度读数列表", "COVER": "拍摄试样遮盖方式（半遮盖/不遮盖/对照）", "SETUP": "远景展现样品与夹具/载物台关系，再近景补充关键接触", "DAMAGE": "逐颗微距拍摄，裂纹/崩瓷/破损处用红圈标注", "DEVICE": "拍摄设备铭牌或管理编号标签，字号清晰", "INDENT": "拍摄压痕测量界面，包含对角线读数和HV计算结果", "RESULT": "拍摄原始曲线、数值结果页面，不要截取报告预览", "EXPOSURE": "拍摄X射线机曝光参数面板或软件曝光参数界面", "FRACTURE": "拍摄断裂后试样断口，含断口形貌和断裂位置", "COOL_TEMP": "拍摄自然冷却后样品表面红外测温读数（23±2℃）", "MC_REPORT": "拍摄最后一个试样的完整试验报告，包含全部试样K值汇总、判定依据和结论。", "OVEN_TEMP": "拍摄烘箱温控器/热电偶读数（100±2℃）", "CTE_REPORT": "拍摄热膨胀仪生成的完整试验报告界面，包含热膨胀系数-温度曲线和计算结果数据表格。", "FIRST_HEAT": "拍摄第一次加热开始/结束的温控器时间和温度", "FREE_END_1": "将测厚仪对准自由端第①测量位置，拍摄测厚仪读数界面及测量位置。", "FREE_END_2": "将测厚仪对准自由端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FREE_END_3": "将测厚仪对准自由端第③测量位置（再偏移约1/3），拍摄方法同上。", "MC_K_VALUE": "拍摄FastTest软件界面或计算表格，清晰显示该试样的K值（τb）计算结果及对应的Ffail值。", "MID_DIST_1": "将测厚仪对准中间段第①测量位置，拍摄测厚仪读数界面及测量位置。", "MID_DIST_2": "将测厚仪对准中间段第②测量位置（沿宽度方向偏移），拍摄方法同上。", "MID_DIST_3": "将测厚仪对准中间段第③测量位置（再偏移），拍摄方法同上。", "PARAMETERS": "拍摄设备控制软件主界面，所有设定参数可见", "RADIOGRAPH": "拍摄原始X射线图像（显示器全屏），包含灰度标尺", "ZERO_FORCE": "拍摄力值清零后的显示界面（显示0 N或<0.1%量程）", "BEND_REPORT": "拍摄最后一个试样的完整试验报告，包含力-位移曲线、Fmax值、弯曲强度计算结果及判定结论。", "COLOR_AFTER": "将试验后试样取出擦干，置于D65标准光源下，与试验前相同角度拍摄，确保前后可比对。", "D65_COMPARE": "拍摄D65灯箱内样品与灰度卡并列比较", "END_DISPLAY": "拍摄结束时氙灯控制屏温度/照度/时间", "FINAL_CURVE": "拍摄最终读数、曲线或结果汇总界面", "FORCE_CURVE": "拍摄力-位移曲线全图，Fmax标记清晰", "H1_BASELINE": "直尺/卡尺对齐基准线，拍摄切割前基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "H2_BASELINE": "直尺/卡尺对齐基准线，拍摄切割后基准线到自由端中点的距离读数，确保刻度清晰可读、无眩光。", "HV_REPORT_1": "拍摄硬度报告第1页，包含样品信息、试验参数（载荷/保荷时间）、各测量点压痕对角线读数。", "HV_REPORT_2": "拍摄硬度报告第2页（续），包含硬度值计算结果、平均值及判定结论。", "SECOND_HEAT": "拍摄第二次加热的温控器时间和温度", "SHOCK_AFTER": "将试验后试样按试验前相同排列方式摆放，拍摄全部试样，便于前后对比裂纹、崩瓷等变化。", "WATER_LEVEL": "拍摄试样安装和水位（试样浸没≥15mm）", "COLOR_BEFORE": "将试样置于D65标准光源下，拍摄试样正面全貌，试样编号清晰可见，背景为中性灰色。", "FIXED_DIST_1": "将测厚仪对准固定端第①测量位置，拍摄测厚仪读数界面及测量位置，试样编号和刻度清晰可见。", "FIXED_DIST_2": "将测厚仪对准固定端第②测量位置（沿宽度方向偏移约1/3），拍摄方法同上。", "FIXED_DIST_3": "将测厚仪对准固定端第③测量位置（再偏移约1/3），拍摄方法同上。", "HV_LOAD_TIME": "拍摄硬度计载荷设定界面或显示屏，同时清晰显示试验力值（如HV10）和保荷时间（如15s）。", "IQI_POSITION": "拍摄样品与孔形像质计在载物台上的实际摆放", "REPORT_PHOTO": "选择最具代表性的一张，用于插入检验报告", "SAMPLE_AFTER": "拍摄实验后样品全貌，有破损或变色时追加局部特写", "SHOCK_BEFORE": "将全部试样编号面朝上摆放整齐，拍摄试样正面清晰全貌，背景为深色以突出陶瓷表面细节。", "THICK_REPORT": "拍摄厚度测量完整报告，包含9个测量点原始读数、平均值计算及判定结论。", "CTE_PARAM_SET": "拍摄热膨胀仪屏幕完整界面，包含升温速率、温度范围、样品长度、气氛等全部参数设定。", "DEFLECTOMETER": "拍摄挠度计与试样接触状态，间隙可见或接触指示", "ROUGH_POINT_1": "将粗糙度仪探头对准试样表面第①测量点，拍摄探头接触位置及周围区域，确保测量点标记在视野内。", "ROUGH_POINT_2": "将粗糙度仪探头对准试样表面第②测量点，拍摄方法同第①点，各测量点间距按SOP均匀分布。", "ROUGH_POINT_3": "将粗糙度仪探头对准试样表面第③测量点，拍摄方法同第①点。", "SAMPLE_BEFORE": "样品+标签在同一画面中，标签信息清晰可读", "SENSOR_FACTOR": "拍摄传感器标定证书或软件传感器系数界面", "START_DISPLAY": "拍摄开始时氙灯控制屏温度/照度/时间", "TARNISH_AFTER": "72h试验结束后取出试样擦干，在D65光源下按试验前相同排列拍摄表面全貌，确保前后可比对。", "TRANSFER_COLD": "拍摄样品从烘箱转移到冰水的过程（≤2s）", "WARP_REPORT_1": "拍摄翘曲变形试验报告第1页，包含样品信息、H1/H2原始读数记录，确保文字和数据清晰。", "WARP_REPORT_2": "拍摄试验报告第2页（续），包含翘曲变形量计算结果和判定结论。", "WARP_REPORT_3": "拍摄试验报告第3页（续），包含备注、签字栏等剩余内容。", "DENSITY_RESULT": "逐试样拍摄天平自动密度结果或打印件，确保试样编号、A、B、水温和密度一一对应。", "HARDNESS_BLOCK": "拍摄标准硬度块证书编号及本次核查压痕", "ICE_TEMP_START": "拍摄试验前冰水混合物温度计读数（1±1℃）", "MEASURE_RESULT": "拍摄各截面（固定/中点/自由端）的测量图像及实测值", "TARNISH_BEFORE": "将全部浸泡与对照试样编号面朝上摆放，在D65标准光源下拍摄试验前表面全貌，背景中性灰。", "OBSERVER_RESULT": "拍摄三名观察者独立填写的比较记录表", "TARNISH_COMPARE": "将浸泡与对照试样并列摆放，D65光源下拍摄前后/对照比较全貌，再用软布擦拭后拍摄同一画面。", "ICE_TEMP_PROCESS": "拍摄试验中每15min冰水温度计复测读数", "INSPECTION_LIGHT": "拍摄照度计在观察位的实测照度（≥1000 lx）", "TARNISH_SOLUTION": "拍摄三批溶液配制记录（初始、24h、48h），包含Na₂S·9H₂O称量、浓度、配制时间和操作人签名。", "ROUGH_CURVE_RESULT": "拍摄设备屏幕完整界面，同一画面内同时包含：轮廓曲线、Ra/Rz计算参数设置和最终测量结果读数。", "DENSITY_CALIBRATION": "拍摄天平内校准、标准密度块或核查样结果，确保编号、密度和判定清晰。"}, "record_template_file": "RECORD_R001_ROUGHNESS.docx", "report_decisive_photo_codes": ["ROUGH_POINT_1", "ROUGH_CURVE_RESULT"]}, "db_mappings": [{"col_index": 2, "field_key": "lambda_s", "row_index": 4, "transform": "text", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "calculation_standard", "row_index": 1, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "sampling_length", "row_index": 7, "transform": "text", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "calculation_standard_ok", "row_index": 1, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 4, "field_key": "clean_ok", "row_index": 4, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 1, "field_key": "sampling_count", "row_index": 8, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "clean_status", "row_index": 4, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "evaluation_length", "row_index": 9, "transform": "text", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "cutoff_filter", "row_index": 3, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 1, "field_key": "surface_confirm", "row_index": 1, "transform": "checkbox", "table_index": 7, "checkbox_selection": ""}, {"col_index": 3, "field_key": "cutoff_filter_ok", "row_index": 3, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 1, "field_key": "mean", "row_index": 1, "transform": "text", "table_index": 8, "checkbox_selection": ""}, {"col_index": 5, "field_key": "deviation_affects_result", "row_index": 1, "transform": "checkbox", "table_index": 9, "checkbox_selection": ""}, {"col_index": 2, "field_key": "deviation_record", "row_index": 1, "transform": "raw", "table_index": 9, "checkbox_selection": ""}, {"col_index": 4, "field_key": "dust_ok", "row_index": 5, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "dust_status", "row_index": 5, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 4, "field_key": "env_humidity_ok", "row_index": 2, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 4, "field_key": "env_temp_ok", "row_index": 1, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 3, "field_key": "evaluation_length_ok", "row_index": 7, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "evaluation_length_ok2", "row_index": 9, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "evaluation_length_value", "row_index": 7, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "evaluation_length_value2", "row_index": 9, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 1, "field_key": "final_conclusion", "row_index": 6, "transform": "text", "table_index": 8, "checkbox_selection": ""}, {"col_index": 1, "field_key": "final_verdict", "row_index": 5, "transform": "checkbox", "table_index": 8, "checkbox_selection": ""}, {"col_index": 3, "field_key": "fixture_conclusion", "row_index": 2, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "fixture_record", "row_index": 2, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "humidity_after", "row_index": 2, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "humidity_before", "row_index": 2, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "interference_col2", "row_index": 3, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 3, "field_key": "interference_col3", "row_index": 3, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 4, "field_key": "interference_ok", "row_index": 3, "transform": "checkbox", "table_index": 2, "checkbox_selection": ""}, {"col_index": 3, "field_key": "lambda_s_ok", "row_index": 2, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "measurement_direction", "row_index": 10, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "measurement_direction_ok", "row_index": 10, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "measurement_range", "row_index": 5, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "measurement_range_ok", "row_index": 5, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "overall_conclusion", "row_index": 6, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "overall_record", "row_index": 6, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "platform_conclusion", "row_index": 1, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "platform_record", "row_index": 1, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "probe_conclusion", "row_index": 5, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "probe_record", "row_index": 5, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "repeat_conclusion", "row_index": 4, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "repeat_record", "row_index": 4, "transform": "raw", "table_index": 4, "checkbox_selection": ""}, {"col_index": 3, "field_key": "sampling_count_ok", "row_index": 8, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 1, "field_key": "sampling_count_select", "row_index": 8, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "sampling_count_value", "row_index": 8, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "sampling_length_ok", "row_index": 6, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 1, "field_key": "sampling_length_select", "row_index": 6, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "sampling_length_value", "row_index": 6, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 2, "field_key": "shape_removal", "row_index": 4, "transform": "raw", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "shape_removal_ok", "row_index": 4, "transform": "checkbox", "table_index": 5, "checkbox_selection": ""}, {"col_index": 3, "field_key": "standard_block_conclusion", "row_index": 3, "transform": "checkbox", "table_index": 4, "checkbox_selection": ""}, {"col_index": 2, "field_key": "standard_block_record", "row_index": 3, "transform": "raw", "table_index": 4, "checkbox_selection": ""}, {"col_index": 1, "field_key": "statistics_failed", "row_index": 2, "transform": "checkbox", "table_index": 8, "checkbox_selection": ""}, {"col_index": 1, "field_key": "statistics_minmax", "row_index": 1, "transform": "raw", "table_index": 8, "checkbox_selection": ""}, {"col_index": 3, "field_key": "temperature_after", "row_index": 1, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "temperature_before", "row_index": 1, "transform": "text", "table_index": 2, "checkbox_selection": ""}, {"col_index": 2, "field_key": "three_length_applicable", "row_index": 0, "transform": "checkbox", "table_index": 6, "checkbox_selection": ""}, {"col_index": 1, "field_key": "three_length_conclusion", "row_index": 3, "transform": "checkbox", "table_index": 8, "checkbox_selection": ""}, {"col_index": 1, "field_key": "three_length_not_applicable", "row_index": 0, "transform": "checkbox", "table_index": 6, "checkbox_selection": ""}]}	30f25ea44426089b97e5ea20d8191f08c5ede5d746d82ba9679ba71762ea9227	2026-08-19 11:51:18.299911+08
\.


--
-- Data for Name: task_packages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.task_packages (package_no, commission_no, group_id, group_no, assignee, reviewer, quality_inspector, material_name, sample_nos, experiment_codes, experiments, status, assigned_by, assigned_at, notified_at, accepted_at, detection_location, acceptance_result, acceptance_note, return_submitted_at, return_confirmed_at, created_at, updated_at, sample_name) FROM stdin;
BAG-BP20260817001-P01	WT20260817001	1	BP20260817001	liuhong_test	lihongli_review	\N	钴铬合金	\N	I002	金属-陶瓷结合裂纹萌生试验	已复核	admin	2026-08-17 15:07:57.103146+08	\N	\N	\N	\N	\N	\N	\N	2026-08-17 15:07:57.103146+08	2026-08-17 15:32:39.781916+08	金瓷结合强度试样
BAG-BP20260818001-P01	WT20260818001	2	BP20260818001	liuhong_test	lihongli_review	\N	钴铬合金	\N	I001, I008, I013	表面粗糙度试验, 维氏硬度试验, 激光选区熔化金属材料密度试验	检测中	receiver	2026-08-18 14:36:49.568793+08	\N	\N	\N	\N	\N	\N	\N	2026-08-18 14:36:49.568793+08	2026-08-18 14:38:18.237151+08	表面粗糙度、硬度、密度、夹杂物和孔隙率试样
BAG-BP20260819001-P01	WT20260819001	3	BP20260819001	liuhong_test	lihongli_review	\N	钴铬合金	\N	I002	金属-陶瓷结合裂纹萌生试验	检测中	admin	2026-08-19 10:35:54.126778+08	\N	\N	\N	\N	\N	\N	\N	2026-08-19 10:35:54.126778+08	2026-08-19 10:36:08.049823+08	金瓷结合性能试样
BAG-BP20260819002-P01	WT20260819002	4	BP20260819002	liuhong_test	lihongli_review	\N	钴铬合金	\N	I012	定制式活动义齿检验	待接收	admin	2026-08-19 10:53:44.975185+08	\N	\N	\N	\N	\N	\N	\N	2026-08-19 10:53:44.975185+08	2026-08-19 10:53:44.975185+08	定制式活动义齿
BAG-BP20260819003-P01	WT20260819003	5	BP20260819003	liuhong_test	lihongli_review	\N	钴铬合金	\N	I012, I003	定制式活动义齿检验, 金属内部质量X射线灰度分析	待接收	admin	2026-08-19 10:58:43.021572+08	\N	\N	\N	\N	\N	\N	\N	2026-08-19 10:58:43.021572+08	2026-08-19 10:58:43.021572+08	定制式活动义齿
BAG-BP20260819004-P01	WT20260819004	6	BP20260819004	liuhong_test	lihongli_review	\N	树脂	\N	I012	定制式活动义齿检验	待接收	admin	2026-08-19 11:00:17.832738+08	\N	\N	\N	\N	\N	\N	\N	2026-08-19 11:00:17.832738+08	2026-08-19 11:00:17.832738+08	定制式活动义齿
BAG-BP20260819005-P01	WT20260819004	7	BP20260819005	liuhong_test	lihongli_review	\N	树脂	\N	I003	金属内部质量X射线灰度分析	检测中	admin	2026-08-19 11:00:32.473894+08	\N	\N	\N	\N	\N	\N	\N	2026-08-19 11:00:32.473894+08	2026-08-19 11:01:59.097779+08	定制式活动义齿
BAG-BP20260819006-P01	WT20260819005	8	BP20260819006	liuhong_test	lihongli_review	\N	钴铬合金	\N	I001	表面粗糙度试验	检测中	admin	2026-08-19 11:50:48.407875+08	\N	\N	\N	\N	\N	\N	\N	2026-08-19 11:50:48.407875+08	2026-08-19 11:51:18.299911+08	牙科用钴铬合金
\.


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tasks (task_no, package_no, commission_no, group_id, group_no, sample_nos, experiment_code, experiment, method_code, standard, material_name, assignee, reviewer, quality_inspector, status, detection_location, experiment_started_at, experiment_ended_at, created_at, updated_at, sample_name) FROM stdin;
BP20260819005-T01	BAG-BP20260819005-P01	WT20260819004	7	BP20260819005	BP20260819005-S01	I003	金属内部质量X射线灰度分析	YY/T1937-2024	YY/T1937-2024《定制式活动义齿》；	树脂	liuhong_test	lihongli_review	quality	检测中	无损检测室	2026-08-19 11:01:59.097779+08	\N	2026-08-19 11:00:32.473894+08	2026-08-19 11:01:59.097779+08	定制式活动义齿
BP20260817001-T01	BAG-BP20260817001-P01	WT20260817001	1	BP20260817001	BP20260817001-S01, BP20260817001-S02	I002	金属-陶瓷结合裂纹萌生试验	YY 0621.1-2016	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》；YY 0621.1-2016 《牙科学 匹配性试验 第1部分： 金属-陶瓷体系》	钴铬合金	liuhong_test	lihongli_review	quality	已复核	性能检测室	2026-08-17 15:09:11.022644+08	2026-08-17 15:22:25.754981+08	2026-08-17 15:07:57.103146+08	2026-08-17 15:32:39.781916+08	金瓷结合强度试样
BP20260819006-T01	BAG-BP20260819006-P01	WT20260819005	8	BP20260819006	BP20260819006-S01	I001	表面粗糙度试验	YY/T 1702-2020	YY/T 1702-2020 《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	钴铬合金	liuhong_test	lihongli_review	quality	检测中	性能检测室	2026-08-19 11:51:18.299911+08	\N	2026-08-19 11:50:48.407875+08	2026-08-19 11:51:18.299911+08	牙科用钴铬合金
BP20260818001-T01	BAG-BP20260818001-P01	WT20260818001	2	BP20260818001	BP20260818001-S01, BP20260818001-S02	I001	表面粗糙度试验	YY/T 1702-2020	YY/T 1702-2020 《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	钴铬合金	liuhong_test	lihongli_review	quality	检测中	性能检测室	2026-08-18 14:38:18.237151+08	\N	2026-08-18 14:36:49.568793+08	2026-08-18 14:38:18.237151+08	表面粗糙度、硬度、密度、夹杂物和孔隙率试样
BP20260818001-T03	BAG-BP20260818001-P01	WT20260818001	2	BP20260818001	BP20260818001-S01, BP20260818001-S02	I013	激光选区熔化金属材料密度试验	YY/T 1702-2020	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》；ISO 22674:2022《牙科学 固定和活动修复体和矫治器用金属材料》	钴铬合金	liuhong_test	lihongli_review	quality	检测中	性能检测室	2026-08-18 14:38:18.237151+08	\N	2026-08-18 14:36:49.568793+08	2026-08-18 14:38:18.237151+08	表面粗糙度、硬度、密度、夹杂物和孔隙率试样
BP20260819001-T01	BAG-BP20260819001-P01	WT20260819001	3	BP20260819001	BP20260819001-S01	I002	金属-陶瓷结合裂纹萌生试验	YY 0621.1-2016	YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》；YY 0621.1-2016 《牙科学 匹配性试验 第1部分： 金属-陶瓷体系》	钴铬合金	liuhong_test	lihongli_review	quality	检测中	性能检测室	2026-08-19 10:36:08.049823+08	\N	2026-08-19 10:35:54.126778+08	2026-08-19 10:36:08.049823+08	金瓷结合性能试样
BP20260818001-T02	BAG-BP20260818001-P01	WT20260818001	2	BP20260818001	BP20260818001-S01, BP20260818001-S02	I008	维氏硬度试验	GB/T 4340.1-2024	GB/T 4340.1-2024《金属材料 维氏硬度试验 第1部分：试验方法》； YY/T 1702-2020《牙科学 增材制造 口腔固定和活动修复用激光选区熔化金属材料》	钴铬合金	liuhong_test	lihongli_review	quality	检测中	性能检测室	2026-08-18 14:38:18.237151+08	\N	2026-08-18 14:36:49.568793+08	2026-08-18 14:38:18.237151+08	表面粗糙度、硬度、密度、夹杂物和孔隙率试样
BP20260819002-T01	BAG-BP20260819002-P01	WT20260819002	4	BP20260819002	BP20260819002-S01	I012	定制式活动义齿检验	YY/T1937-2024	YY/T1937-2024《定制式活动义齿》	钴铬合金	liuhong_test	lihongli_review	quality	待接收	性能检测室	\N	\N	2026-08-19 10:53:44.975185+08	2026-08-19 10:53:44.975185+08	定制式活动义齿
BP20260819003-T01	BAG-BP20260819003-P01	WT20260819003	5	BP20260819003	BP20260819003-S01	I012	定制式活动义齿检验	YY/T1937-2024	YY/T1937-2024《定制式活动义齿》	钴铬合金	liuhong_test	lihongli_review	quality	待接收	性能检测室	\N	\N	2026-08-19 10:58:43.021572+08	2026-08-19 10:58:43.021572+08	定制式活动义齿
BP20260819003-T02	BAG-BP20260819003-P01	WT20260819003	5	BP20260819003	BP20260819003-S01	I003	金属内部质量X射线灰度分析	YY/T1937-2024	YY/T1937-2024《定制式活动义齿》；	钴铬合金	liuhong_test	lihongli_review	quality	待接收	性能检测室	\N	\N	2026-08-19 10:58:43.021572+08	2026-08-19 10:58:43.021572+08	定制式活动义齿
BP20260819004-T01	BAG-BP20260819004-P01	WT20260819004	6	BP20260819004	BP20260819004-S01	I012	定制式活动义齿检验	YY/T1937-2024	YY/T1937-2024《定制式活动义齿》	树脂	liuhong_test	lihongli_review	quality	待接收	性能检测室	\N	\N	2026-08-19 11:00:17.832738+08	2026-08-19 11:00:17.832738+08	定制式活动义齿
\.


--
-- Data for Name: template_field_mappings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.template_field_mappings (id, config_id, field_source, field_key, template_name, table_index, row_index, col_index, transform, checkbox_selection, sort_order, created_at, updated_at) FROM stdin;
857	1	static	calculation_standard	RECORD_R001_ROUGHNESS.docx	5	1	2	raw		0	2026-08-16 15:39:41.341724+08	\N
858	1	static	calculation_standard_ok	RECORD_R001_ROUGHNESS.docx	5	1	3	checkbox		1	2026-08-16 15:39:41.341724+08	\N
859	1	static	clean_ok	RECORD_R001_ROUGHNESS.docx	2	4	4	checkbox		2	2026-08-16 15:39:41.341724+08	\N
860	1	static	clean_status	RECORD_R001_ROUGHNESS.docx	2	4	2	checkbox		3	2026-08-16 15:39:41.341724+08	\N
861	1	static	cutoff_filter	RECORD_R001_ROUGHNESS.docx	5	3	2	raw		4	2026-08-16 15:39:41.341724+08	\N
862	1	static	cutoff_filter_ok	RECORD_R001_ROUGHNESS.docx	5	3	3	checkbox		5	2026-08-16 15:39:41.341724+08	\N
863	1	static	deviation_affects_result	RECORD_R001_ROUGHNESS.docx	9	1	5	checkbox		6	2026-08-16 15:39:41.341724+08	\N
864	1	static	deviation_record	RECORD_R001_ROUGHNESS.docx	9	1	2	raw		7	2026-08-16 15:39:41.341724+08	\N
865	1	static	dust_ok	RECORD_R001_ROUGHNESS.docx	2	5	4	checkbox		8	2026-08-16 15:39:41.341724+08	\N
866	1	static	dust_status	RECORD_R001_ROUGHNESS.docx	2	5	2	checkbox		9	2026-08-16 15:39:41.341724+08	\N
867	1	static	env_humidity_ok	RECORD_R001_ROUGHNESS.docx	2	2	4	checkbox		10	2026-08-16 15:39:41.341724+08	\N
868	1	static	env_temp_ok	RECORD_R001_ROUGHNESS.docx	2	1	4	checkbox		11	2026-08-16 15:39:41.341724+08	\N
869	1	static	evaluation_length_ok	RECORD_R001_ROUGHNESS.docx	5	7	3	checkbox		12	2026-08-16 15:39:41.341724+08	\N
870	1	static	evaluation_length_ok2	RECORD_R001_ROUGHNESS.docx	5	9	3	checkbox		13	2026-08-16 15:39:41.341724+08	\N
871	1	static	evaluation_length_value	RECORD_R001_ROUGHNESS.docx	5	7	2	raw		14	2026-08-16 15:39:41.341724+08	\N
872	1	static	evaluation_length_value2	RECORD_R001_ROUGHNESS.docx	5	9	2	raw		15	2026-08-16 15:39:41.341724+08	\N
873	1	static	final_conclusion	RECORD_R001_ROUGHNESS.docx	8	6	1	text		16	2026-08-16 15:39:41.341724+08	\N
874	1	static	final_verdict	RECORD_R001_ROUGHNESS.docx	8	5	1	checkbox		17	2026-08-16 15:39:41.341724+08	\N
875	1	static	fixture_conclusion	RECORD_R001_ROUGHNESS.docx	4	2	3	checkbox		18	2026-08-16 15:39:41.341724+08	\N
876	1	static	fixture_record	RECORD_R001_ROUGHNESS.docx	4	2	2	checkbox		19	2026-08-16 15:39:41.341724+08	\N
877	1	static	humidity_after	RECORD_R001_ROUGHNESS.docx	2	2	3	text		20	2026-08-16 15:39:41.341724+08	\N
878	1	static	humidity_before	RECORD_R001_ROUGHNESS.docx	2	2	2	text		21	2026-08-16 15:39:41.341724+08	\N
879	1	static	interference_col2	RECORD_R001_ROUGHNESS.docx	2	3	2	checkbox		22	2026-08-16 15:39:41.341724+08	\N
880	1	static	interference_col3	RECORD_R001_ROUGHNESS.docx	2	3	3	checkbox		23	2026-08-16 15:39:41.341724+08	\N
881	1	static	interference_ok	RECORD_R001_ROUGHNESS.docx	2	3	4	checkbox		24	2026-08-16 15:39:41.341724+08	\N
883	1	static	lambda_s_ok	RECORD_R001_ROUGHNESS.docx	5	2	3	checkbox		26	2026-08-16 15:39:41.341724+08	\N
884	1	static	measurement_direction	RECORD_R001_ROUGHNESS.docx	5	10	2	raw		27	2026-08-16 15:39:41.341724+08	\N
885	1	static	measurement_direction_ok	RECORD_R001_ROUGHNESS.docx	5	10	3	checkbox		28	2026-08-16 15:39:41.341724+08	\N
886	1	static	measurement_range	RECORD_R001_ROUGHNESS.docx	5	5	2	raw		29	2026-08-16 15:39:41.341724+08	\N
887	1	static	measurement_range_ok	RECORD_R001_ROUGHNESS.docx	5	5	3	checkbox		30	2026-08-16 15:39:41.341724+08	\N
888	1	static	overall_conclusion	RECORD_R001_ROUGHNESS.docx	4	6	3	checkbox		31	2026-08-16 15:39:41.341724+08	\N
889	1	static	overall_record	RECORD_R001_ROUGHNESS.docx	4	6	2	checkbox		32	2026-08-16 15:39:41.341724+08	\N
890	1	static	platform_conclusion	RECORD_R001_ROUGHNESS.docx	4	1	3	checkbox		33	2026-08-16 15:39:41.341724+08	\N
891	1	static	platform_record	RECORD_R001_ROUGHNESS.docx	4	1	2	checkbox		34	2026-08-16 15:39:41.341724+08	\N
892	1	static	probe_conclusion	RECORD_R001_ROUGHNESS.docx	4	5	3	checkbox		35	2026-08-16 15:39:41.341724+08	\N
893	1	static	probe_record	RECORD_R001_ROUGHNESS.docx	4	5	2	checkbox		36	2026-08-16 15:39:41.341724+08	\N
894	1	static	repeat_conclusion	RECORD_R001_ROUGHNESS.docx	4	4	3	checkbox		37	2026-08-16 15:39:41.341724+08	\N
895	1	static	repeat_record	RECORD_R001_ROUGHNESS.docx	4	4	2	raw		38	2026-08-16 15:39:41.341724+08	\N
896	1	static	sampling_count_ok	RECORD_R001_ROUGHNESS.docx	5	8	3	checkbox		39	2026-08-16 15:39:41.341724+08	\N
897	1	static	sampling_count_select	RECORD_R001_ROUGHNESS.docx	5	8	1	checkbox		40	2026-08-16 15:39:41.341724+08	\N
898	1	static	sampling_count_value	RECORD_R001_ROUGHNESS.docx	5	8	2	raw		41	2026-08-16 15:39:41.341724+08	\N
899	1	static	sampling_length_ok	RECORD_R001_ROUGHNESS.docx	5	6	3	checkbox		42	2026-08-16 15:39:41.341724+08	\N
900	1	static	sampling_length_select	RECORD_R001_ROUGHNESS.docx	5	6	1	checkbox		43	2026-08-16 15:39:41.341724+08	\N
901	1	static	sampling_length_value	RECORD_R001_ROUGHNESS.docx	5	6	2	raw		44	2026-08-16 15:39:41.341724+08	\N
902	1	static	shape_removal	RECORD_R001_ROUGHNESS.docx	5	4	2	raw		45	2026-08-16 15:39:41.341724+08	\N
903	1	static	shape_removal_ok	RECORD_R001_ROUGHNESS.docx	5	4	3	checkbox		46	2026-08-16 15:39:41.341724+08	\N
904	1	static	standard_block_conclusion	RECORD_R001_ROUGHNESS.docx	4	3	3	checkbox		47	2026-08-16 15:39:41.341724+08	\N
905	1	static	standard_block_record	RECORD_R001_ROUGHNESS.docx	4	3	2	raw		48	2026-08-16 15:39:41.341724+08	\N
906	1	static	statistics_failed	RECORD_R001_ROUGHNESS.docx	8	2	1	checkbox		49	2026-08-16 15:39:41.341724+08	\N
913	3	static	density_mean	RECORD_R005_XRAY.docx	4	1	5	text		0	2026-08-16 15:39:41.341724+08	\N
907	1	static	statistics_minmax	RECORD_R001_ROUGHNESS.docx	8	1	1	raw		50	2026-08-16 15:39:41.341724+08	\N
908	1	static	temperature_after	RECORD_R001_ROUGHNESS.docx	2	1	3	text		51	2026-08-16 15:39:41.341724+08	\N
909	1	static	temperature_before	RECORD_R001_ROUGHNESS.docx	2	1	2	text		52	2026-08-16 15:39:41.341724+08	\N
910	1	static	three_length_applicable	RECORD_R001_ROUGHNESS.docx	6	0	2	checkbox		53	2026-08-16 15:39:41.341724+08	\N
911	1	static	three_length_conclusion	RECORD_R001_ROUGHNESS.docx	8	3	1	checkbox		54	2026-08-16 15:39:41.341724+08	\N
912	1	static	three_length_not_applicable	RECORD_R001_ROUGHNESS.docx	6	0	1	checkbox		55	2026-08-16 15:39:41.341724+08	\N
914	3	static	density_verdict	RECORD_R005_XRAY.docx	4	1	7	checkbox		1	2026-08-16 15:39:41.341724+08	\N
915	3	static	end_time	RECORD_R005_XRAY.docx	2	0	3	text		2	2026-08-16 15:39:41.341724+08	\N
916	3	static	humidity_before	RECORD_R005_XRAY.docx	2	2	1	text		3	2026-08-16 15:39:41.341724+08	\N
917	3	static	humidity_ok	RECORD_R005_XRAY.docx	2	2	5	checkbox		4	2026-08-16 15:39:41.341724+08	\N
918	3	static	image_no_t7	RECORD_R005_XRAY.docx	7	0	6	text		5	2026-08-16 15:39:41.341724+08	\N
919	3	static	operator_t2	RECORD_R005_XRAY.docx	2	0	5	text		6	2026-08-16 15:39:41.341724+08	\N
920	3	static	operator_t7	RECORD_R005_XRAY.docx	7	1	6	text		7	2026-08-16 15:39:41.341724+08	\N
921	3	static	reviewer_t7	RECORD_R005_XRAY.docx	7	1	10	text		8	2026-08-16 15:39:41.341724+08	\N
922	3	static	sample_no_t7	RECORD_R005_XRAY.docx	7	0	2	text		9	2026-08-16 15:39:41.341724+08	\N
923	3	static	software	RECORD_R005_XRAY.docx	7	1	2	text		10	2026-08-16 15:39:41.341724+08	\N
924	3	static	start_time	RECORD_R005_XRAY.docx	2	0	1	text		11	2026-08-16 15:39:41.341724+08	\N
925	3	static	temperature_before	RECORD_R005_XRAY.docx	2	1	1	text		12	2026-08-16 15:39:41.341724+08	\N
926	3	static	temperature_ok	RECORD_R005_XRAY.docx	2	1	5	checkbox		13	2026-08-16 15:39:41.341724+08	\N
927	3	static	test_date	RECORD_R005_XRAY.docx	7	0	10	text		14	2026-08-16 15:39:41.341724+08	\N
928	5	static	alpha_mean	RECORD_R007_CTE.docx	8	1	1	text		0	2026-08-16 15:39:41.341724+08	\N
929	5	static	attachment_ref_t8	RECORD_R007_CTE.docx	8	2	3	text		1	2026-08-16 15:39:41.341724+08	\N
930	5	static	delta_l_max	RECORD_R007_CTE.docx	8	2	1	text		2	2026-08-16 15:39:41.341724+08	\N
931	5	static	final_verdict	RECORD_R007_CTE.docx	8	0	1	checkbox		3	2026-08-16 15:39:41.341724+08	\N
932	5	static	humidity_before	RECORD_R007_CTE.docx	1	2	2	text		4	2026-08-16 15:39:41.341724+08	\N
933	5	static	temperature_before	RECORD_R007_CTE.docx	1	1	2	text		5	2026-08-16 15:39:41.341724+08	\N
934	5	static	temperature_range	RECORD_R007_CTE.docx	8	1	3	raw		6	2026-08-16 15:39:41.341724+08	\N
935	6	static	appearance_check	RECORD_R009_THERMAL_SHOCK.docx	4	1	2	checkbox		0	2026-08-16 15:39:41.341724+08	\N
936	6	static	chipping_count	RECORD_R009_THERMAL_SHOCK.docx	9	1	3	text		1	2026-08-16 15:39:41.341724+08	\N
937	6	static	container_no	RECORD_R009_THERMAL_SHOCK.docx	6	1	0	text		2	2026-08-16 15:39:41.341724+08	\N
938	6	static	cooling_record	RECORD_R009_THERMAL_SHOCK.docx	7	3	2	text		3	2026-08-16 15:39:41.341724+08	\N
939	6	static	cooling_temp_record	RECORD_R009_THERMAL_SHOCK.docx	7	1	2	text		4	2026-08-16 15:39:41.341724+08	\N
940	6	static	crack_count	RECORD_R009_THERMAL_SHOCK.docx	9	1	1	text		5	2026-08-16 15:39:41.341724+08	\N
941	6	static	env_humidity_ok	RECORD_R009_THERMAL_SHOCK.docx	1	2	4	checkbox		6	2026-08-16 15:39:41.341724+08	\N
942	6	static	env_temp_ok	RECORD_R009_THERMAL_SHOCK.docx	1	1	4	checkbox		7	2026-08-16 15:39:41.341724+08	\N
943	6	static	final_conclusion	RECORD_R009_THERMAL_SHOCK.docx	9	4	1	checkbox		8	2026-08-16 15:39:41.341724+08	\N
944	6	static	final_verdict	RECORD_R009_THERMAL_SHOCK.docx	9	3	3	checkbox		9	2026-08-16 15:39:41.341724+08	\N
945	6	static	first_heating_interval	RECORD_R009_THERMAL_SHOCK.docx	6	1	2	text		10	2026-08-16 15:39:41.341724+08	\N
946	6	static	first_heating_record	RECORD_R009_THERMAL_SHOCK.docx	4	3	2	text		11	2026-08-16 15:39:41.341724+08	\N
947	6	static	fracture_count	RECORD_R009_THERMAL_SHOCK.docx	9	2	1	text		12	2026-08-16 15:39:41.341724+08	\N
948	6	static	humidity_after	RECORD_R009_THERMAL_SHOCK.docx	1	2	3	text		13	2026-08-16 15:39:41.341724+08	\N
949	6	static	humidity_before	RECORD_R009_THERMAL_SHOCK.docx	1	2	2	text		14	2026-08-16 15:39:41.341724+08	\N
950	6	static	ice_bath_record	RECORD_R009_THERMAL_SHOCK.docx	4	4	2	text		15	2026-08-16 15:39:41.341724+08	\N
951	6	static	ice_immersion_record	RECORD_R009_THERMAL_SHOCK.docx	4	7	2	text		16	2026-08-16 15:39:41.341724+08	\N
952	6	static	ice_water_record	RECORD_R009_THERMAL_SHOCK.docx	4	5	2	text		17	2026-08-16 15:39:41.341724+08	\N
953	6	static	illumination_col2	RECORD_R009_THERMAL_SHOCK.docx	1	3	2	text		18	2026-08-16 15:39:41.341724+08	\N
954	6	static	illumination_col3	RECORD_R009_THERMAL_SHOCK.docx	1	3	3	text		19	2026-08-16 15:39:41.341724+08	\N
955	6	static	illumination_ok	RECORD_R009_THERMAL_SHOCK.docx	1	3	4	checkbox		20	2026-08-16 15:39:41.341724+08	\N
956	6	static	illumination_record	RECORD_R009_THERMAL_SHOCK.docx	7	4	2	text		21	2026-08-16 15:39:41.341724+08	\N
957	6	static	immersion_interval	RECORD_R009_THERMAL_SHOCK.docx	6	1	4	text		22	2026-08-16 15:39:41.341724+08	\N
958	6	static	inspector_record	RECORD_R009_THERMAL_SHOCK.docx	7	5	2	text		23	2026-08-16 15:39:41.341724+08	\N
959	6	static	oven_temperature_record	RECORD_R009_THERMAL_SHOCK.docx	4	2	2	text		24	2026-08-16 15:39:41.341724+08	\N
960	6	static	sample_count	RECORD_R009_THERMAL_SHOCK.docx	6	1	1	text		25	2026-08-16 15:39:41.341724+08	\N
961	6	static	second_heating_interval	RECORD_R009_THERMAL_SHOCK.docx	6	1	5	text		26	2026-08-16 15:39:41.341724+08	\N
962	6	static	second_heating_record	RECORD_R009_THERMAL_SHOCK.docx	4	8	2	text		27	2026-08-16 15:39:41.341724+08	\N
963	6	static	surface_temp_record	RECORD_R009_THERMAL_SHOCK.docx	7	2	2	text		28	2026-08-16 15:39:41.341724+08	\N
964	6	static	temperature_after	RECORD_R009_THERMAL_SHOCK.docx	1	1	3	text		29	2026-08-16 15:39:41.341724+08	\N
965	6	static	temperature_before	RECORD_R009_THERMAL_SHOCK.docx	1	1	2	text		30	2026-08-16 15:39:41.341724+08	\N
966	6	static	total_count	RECORD_R009_THERMAL_SHOCK.docx	9	0	1	text		31	2026-08-16 15:39:41.341724+08	\N
967	6	static	total_count_2	RECORD_R009_THERMAL_SHOCK.docx	9	0	3	text		32	2026-08-16 15:39:41.341724+08	\N
968	6	static	transfer_interval	RECORD_R009_THERMAL_SHOCK.docx	6	1	3	text		33	2026-08-16 15:39:41.341724+08	\N
969	6	static	transfer_time_record	RECORD_R009_THERMAL_SHOCK.docx	4	6	2	text		34	2026-08-16 15:39:41.341724+08	\N
970	7	static	attachment_ref_t7	RECORD_R010_BENDING.docx	7	0	1	text		0	2026-08-16 15:39:41.341724+08	\N
971	7	static	has_attachment_a	RECORD_R010_BENDING.docx	7	1	1	checkbox		1	2026-08-16 15:39:41.341724+08	\N
972	7	static	has_attachment_b	RECORD_R010_BENDING.docx	7	1	3	checkbox		2	2026-08-16 15:39:41.341724+08	\N
973	7	static	overall_verdict	RECORD_R010_BENDING.docx	4	7	0	checkbox		3	2026-08-16 15:39:41.341724+08	\N
974	8	static	indent_method	RECORD_R011_VICKERS.docx	3	1	1	checkbox		0	2026-08-16 15:39:41.341724+08	\N
975	8	static	perpendicularity	RECORD_R011_VICKERS.docx	2	5	5	checkbox		1	2026-08-16 15:39:41.341724+08	\N
976	8	static	report_exported	RECORD_R011_VICKERS.docx	3	2	3	checkbox		2	2026-08-16 15:39:41.341724+08	\N
977	8	static	report_exported_ok	RECORD_R011_VICKERS.docx	3	2	5	checkbox		3	2026-08-16 15:39:41.341724+08	\N
978	8	static	standard_block_due	RECORD_R011_VICKERS.docx	2	1	5	text		4	2026-08-16 15:39:41.341724+08	\N
979	8	static	std_reading_1	RECORD_R011_VICKERS.docx	2	2	3	text		5	2026-08-16 15:39:41.341724+08	\N
980	8	static	std_reading_2	RECORD_R011_VICKERS.docx	2	2	5	text		6	2026-08-16 15:39:41.341724+08	\N
981	8	static	std_reading_3	RECORD_R011_VICKERS.docx	2	3	1	text		7	2026-08-16 15:39:41.341724+08	\N
982	8	static	std_reading_mean	RECORD_R011_VICKERS.docx	2	3	3	text		8	2026-08-16 15:39:41.341724+08	\N
983	8	static	std_result	RECORD_R011_VICKERS.docx	2	3	5	checkbox		9	2026-08-16 15:39:41.341724+08	\N
984	8	static	surface_condition	RECORD_R011_VICKERS.docx	2	5	1	checkbox		10	2026-08-16 15:39:41.341724+08	\N
985	8	static	surface_verdict	RECORD_R011_VICKERS.docx	2	4	5	checkbox		11	2026-08-16 15:39:41.341724+08	\N
986	9	static	calibration_record	RECORD_R013_THICKNESS.docx	2	3	2	text		0	2026-08-16 15:39:41.341724+08	\N
987	9	static	design_file_no	RECORD_R013_THICKNESS.docx	0	7	5	text		1	2026-08-16 15:39:41.341724+08	\N
988	9	static	magnification_record	RECORD_R013_THICKNESS.docx	2	1	2	text		2	2026-08-16 15:39:41.341724+08	\N
989	9	static	preheat_record	RECORD_R013_THICKNESS.docx	2	2	2	text		3	2026-08-16 15:39:41.341724+08	\N
990	9	static	production_date	RECORD_R013_THICKNESS.docx	0	7	3	text		4	2026-08-16 15:39:41.341724+08	\N
991	9	static	sample_batch	RECORD_R013_THICKNESS.docx	0	7	1	text		5	2026-08-16 15:39:41.341724+08	\N
992	10	static	attachment_ref_t7	RECORD_R012_COLOR_STABILITY.docx	7	2	1	text		0	2026-08-16 15:39:41.341724+08	\N
993	10	static	background	RECORD_R012_COLOR_STABILITY.docx	9	2	1	checkbox		1	2026-08-16 15:39:41.341724+08	\N
994	10	static	background_ok	RECORD_R012_COLOR_STABILITY.docx	9	2	3	checkbox		2	2026-08-16 15:39:41.341724+08	\N
995	10	static	d65_illuminance	RECORD_R012_COLOR_STABILITY.docx	9	1	3	text		3	2026-08-16 15:39:41.341724+08	\N
996	10	static	device_status	RECORD_R012_COLOR_STABILITY.docx	5	7	2	checkbox		4	2026-08-16 15:39:41.341724+08	\N
997	10	static	exposure_end	RECORD_R012_COLOR_STABILITY.docx	7	0	3	text		5	2026-08-16 15:39:41.341724+08	\N
998	10	static	exposure_ok	RECORD_R012_COLOR_STABILITY.docx	7	1	3	checkbox		6	2026-08-16 15:39:41.341724+08	\N
999	10	static	exposure_start	RECORD_R012_COLOR_STABILITY.docx	7	0	1	text		7	2026-08-16 15:39:41.341724+08	\N
1000	10	static	exposure_time	RECORD_R012_COLOR_STABILITY.docx	7	1	1	text		8	2026-08-16 15:39:41.341724+08	\N
1001	10	static	exposure_time_record	RECORD_R012_COLOR_STABILITY.docx	5	5	2	text		9	2026-08-16 15:39:41.341724+08	\N
1002	10	static	filter_hours	RECORD_R012_COLOR_STABILITY.docx	4	1	3	text		10	2026-08-16 15:39:41.341724+08	\N
1003	10	static	filter_no	RECORD_R012_COLOR_STABILITY.docx	4	1	1	text		11	2026-08-16 15:39:41.341724+08	\N
1004	10	static	final_verdict	RECORD_R012_COLOR_STABILITY.docx	11	13	7	checkbox		12	2026-08-16 15:39:41.341724+08	\N
1005	10	static	handling_status	RECORD_R012_COLOR_STABILITY.docx	9	0	3	checkbox		13	2026-08-16 15:39:41.341724+08	\N
1006	10	static	has_attachment_a	RECORD_R012_COLOR_STABILITY.docx	7	3	1	checkbox		14	2026-08-16 15:39:41.341724+08	\N
1007	10	static	has_attachment_b	RECORD_R012_COLOR_STABILITY.docx	7	3	3	checkbox		15	2026-08-16 15:39:41.341724+08	\N
1008	10	static	humidity_before	RECORD_R012_COLOR_STABILITY.docx	1	0	5	text		16	2026-08-16 15:39:41.341724+08	\N
1009	10	static	lamp_box_ready	RECORD_R012_COLOR_STABILITY.docx	9	1	1	checkbox		17	2026-08-16 15:39:41.341724+08	\N
1010	10	static	lamp_calibrated	RECORD_R012_COLOR_STABILITY.docx	4	2	3	checkbox		18	2026-08-16 15:39:41.341724+08	\N
1011	10	static	lamp_history	RECORD_R012_COLOR_STABILITY.docx	4	3	3	checkbox		19	2026-08-16 15:39:41.341724+08	\N
1012	10	static	lamp_hours	RECORD_R012_COLOR_STABILITY.docx	4	0	3	text		20	2026-08-16 15:39:41.341724+08	\N
1013	10	static	lamp_no	RECORD_R012_COLOR_STABILITY.docx	4	0	1	text		21	2026-08-16 15:39:41.341724+08	\N
1014	10	static	lightbox_clean	RECORD_R012_COLOR_STABILITY.docx	1	2	5	checkbox		22	2026-08-16 15:39:41.341724+08	\N
1015	10	static	lightbox_confirmed	RECORD_R012_COLOR_STABILITY.docx	1	3	5	checkbox		23	2026-08-16 15:39:41.341724+08	\N
1016	10	static	lightbox_type	RECORD_R012_COLOR_STABILITY.docx	1	2	1	checkbox		24	2026-08-16 15:39:41.341724+08	\N
1017	10	static	observation_conditions	RECORD_R012_COLOR_STABILITY.docx	9	4	1	checkbox		25	2026-08-16 15:39:41.341724+08	\N
1018	10	static	observation_date	RECORD_R012_COLOR_STABILITY.docx	9	4	3	text		26	2026-08-16 15:39:41.341724+08	\N
1019	10	static	observation_distance	RECORD_R012_COLOR_STABILITY.docx	9	3	1	text		27	2026-08-16 15:39:41.341724+08	\N
1020	10	static	overall_verdict	RECORD_R012_COLOR_STABILITY.docx	11	13	2	checkbox		28	2026-08-16 15:39:41.341724+08	\N
1021	10	static	sample_handling	RECORD_R012_COLOR_STABILITY.docx	9	0	1	checkbox		29	2026-08-16 15:39:41.341724+08	\N
1022	10	static	sample_illuminance	RECORD_R012_COLOR_STABILITY.docx	5	3	2	text		30	2026-08-16 15:39:41.341724+08	\N
1023	10	static	sample_placement	RECORD_R012_COLOR_STABILITY.docx	5	6	2	checkbox		31	2026-08-16 15:39:41.341724+08	\N
1024	10	static	single_observation_time	RECORD_R012_COLOR_STABILITY.docx	9	3	3	text		32	2026-08-16 15:39:41.341724+08	\N
1025	10	static	source_type	RECORD_R012_COLOR_STABILITY.docx	5	1	2	checkbox		33	2026-08-16 15:39:41.341724+08	\N
1026	10	static	temperature_before	RECORD_R012_COLOR_STABILITY.docx	1	0	1	text		34	2026-08-16 15:39:41.341724+08	\N
1027	10	static	trace_ref	RECORD_R012_COLOR_STABILITY.docx	7	2	3	text		35	2026-08-16 15:39:41.341724+08	\N
1028	10	static	water_distance	RECORD_R012_COLOR_STABILITY.docx	5	4	2	text		36	2026-08-16 15:39:41.341724+08	\N
1029	10	static	water_temp_record	RECORD_R012_COLOR_STABILITY.docx	5	2	2	text		37	2026-08-16 15:39:41.341724+08	\N
1030	11	static	attachment_ref_t10	R014_定制式固定义齿检验_CMA原始记录表.docx	10	6	1	text		0	2026-08-16 15:39:41.341724+08	\N
1031	11	static	final_verdict	R014_定制式固定义齿检验_CMA原始记录表.docx	10	5	1	checkbox		1	2026-08-16 15:39:41.341724+08	\N
1032	11	static	porosity_result	R014_定制式固定义齿检验_CMA原始记录表.docx	10	1	1	checkbox		2	2026-08-16 15:39:41.341724+08	\N
1033	11	static	roughness_result	R014_定制式固定义齿检验_CMA原始记录表.docx	10	4	1	checkbox		3	2026-08-16 15:39:41.341724+08	\N
1034	12	static	attachment_ref_t9a	R015_定制式活动义齿检验_CMA原始记录表.docx	9	2	1	text		0	2026-08-16 15:39:41.341724+08	\N
1035	12	static	attachment_ref_t9b	R015_定制式活动义齿检验_CMA原始记录表.docx	9	6	1	text		1	2026-08-16 15:39:41.341724+08	\N
1036	12	static	cutting_device_no	R015_定制式活动义齿检验_CMA原始记录表.docx	10	1	2	text		2	2026-08-16 15:39:41.341724+08	\N
1037	12	static	final_conclusion	R015_定制式活动义齿检验_CMA原始记录表.docx	15	1	1	checkbox		3	2026-08-16 15:39:41.341724+08	\N
1038	12	static	final_no	R015_定制式活动义齿检验_CMA原始记录表.docx	15	4	1	checkbox		4	2026-08-16 15:39:41.341724+08	\N
1039	12	static	inner_angle	R015_定制式活动义齿检验_CMA原始记录表.docx	10	3	3	text		5	2026-08-16 15:39:41.341724+08	\N
1040	12	static	iqi_no	R015_定制式活动义齿检验_CMA原始记录表.docx	9	3	1	text		6	2026-08-16 15:39:41.341724+08	\N
1041	12	static	lower_no_pore_faces	R015_定制式活动义齿检验_CMA原始记录表.docx	11	2	7	text		7	2026-08-16 15:39:41.341724+08	\N
1042	12	static	outer_angle	R015_定制式活动义齿检验_CMA原始记录表.docx	10	2	3	text		8	2026-08-16 15:39:41.341724+08	\N
1043	12	static	porosity_lower	R015_定制式活动义齿检验_CMA原始记录表.docx	11	2	8	checkbox		9	2026-08-16 15:39:41.341724+08	\N
1044	12	static	porosity_upper	R015_定制式活动义齿检验_CMA原始记录表.docx	11	1	8	checkbox		10	2026-08-16 15:39:41.341724+08	\N
1045	12	static	same_vertical	R015_定制式活动义齿检验_CMA原始记录表.docx	10	4	3	checkbox		11	2026-08-16 15:39:41.341724+08	\N
1046	12	static	termination_inner	R015_定制式活动义齿检验_CMA原始记录表.docx	10	3	4	checkbox		12	2026-08-16 15:39:41.341724+08	\N
1047	12	static	termination_outer	R015_定制式活动义齿检验_CMA原始记录表.docx	10	2	4	checkbox		13	2026-08-16 15:39:41.341724+08	\N
1048	12	static	termination_vertical	R015_定制式活动义齿检验_CMA原始记录表.docx	10	4	4	checkbox		14	2026-08-16 15:39:41.341724+08	\N
1049	12	static	upper_no_pore_faces	R015_定制式活动义齿检验_CMA原始记录表.docx	11	1	7	text		15	2026-08-16 15:39:41.341724+08	\N
1050	12	static	xray_conclusion	R015_定制式活动义齿检验_CMA原始记录表.docx	9	10	1	checkbox		16	2026-08-16 15:39:41.341724+08	\N
1051	13	static	attachment_ref_t10	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	10	4	1	text		0	2026-08-16 15:39:41.341724+08	\N
1052	13	static	auto_calc_check	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	4	4	5	checkbox		1	2026-08-16 15:39:41.341724+08	\N
1053	13	static	balance_calibration	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	2	0	7	checkbox		2	2026-08-16 15:39:41.341724+08	\N
1054	13	static	declared_density	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	10	1	3	text		3	2026-08-16 15:39:41.341724+08	\N
1055	13	static	declared_source	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	10	1	1	text		4	2026-08-16 15:39:41.341724+08	\N
1056	13	static	density_verdict	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	10	3	1	checkbox		5	2026-08-16 15:39:41.341724+08	\N
1057	13	static	overall_mean	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	7	7	3	text		6	2026-08-16 15:39:41.341724+08	\N
1058	13	static	overall_mean_1dp	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	7	7	8	text		7	2026-08-16 15:39:41.341724+08	\N
1059	13	static	overall_verdict	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	7	7	10	checkbox		8	2026-08-16 15:39:41.341724+08	\N
1060	13	static	system_check	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	3	6	6	checkbox		9	2026-08-16 15:39:41.341724+08	\N
1061	14	static	attachment_ref_t12	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	12	4	3	text		0	2026-08-16 15:39:41.341724+08	\N
1062	14	static	bath_status	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	8	2	checkbox		1	2026-08-16 15:39:41.341724+08	\N
1063	14	static	bath_temperature	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	2	2	text		2	2026-08-16 15:39:41.341724+08	\N
1064	14	static	bath_volume	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	1	2	text		3	2026-08-16 15:39:41.341724+08	\N
1065	14	static	color_change_verdict	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	9	1	1	checkbox		4	2026-08-16 15:39:41.341724+08	\N
1066	14	static	control_color_change	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	5	2	text		5	2026-08-16 15:39:41.341724+08	\N
1067	14	static	cycle_immersion_seconds	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	3	2	text		6	2026-08-16 15:39:41.341724+08	\N
1068	14	static	final_conclusion	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	12	2	1	checkbox		7	2026-08-16 15:39:41.341724+08	\N
1069	14	static	immersed_color_change	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	5	1	text		8	2026-08-16 15:39:41.341724+08	\N
1070	14	static	immersed_sample_no	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	8	1	0	text		9	2026-08-16 15:39:41.341724+08	\N
1071	14	static	observation_distance	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	3	3	text		10	2026-08-16 15:39:41.341724+08	\N
1072	14	static	observation_illuminance	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	2	3	text		11	2026-08-16 15:39:41.341724+08	\N
1073	14	static	reflectance_change	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	6	1	text		12	2026-08-16 15:39:41.341724+08	\N
1074	14	static	reflectance_verdict	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	9	3	1	text		13	2026-08-16 15:39:41.341724+08	\N
1075	14	static	removal_ease	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	8	1	3	checkbox		14	2026-08-16 15:39:41.341724+08	\N
1076	14	static	removal_ease_verdict	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	9	2	1	checkbox		15	2026-08-16 15:39:41.341724+08	\N
1077	14	static	result_valid	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	12	1	1	checkbox		16	2026-08-16 15:39:41.341724+08	\N
1083	1	static	lambda_s	RECORD_R001_ROUGHNESS.docx	5	4	2	text		0	2026-08-19 10:29:56.819659+08	\N
1084	1	static	sampling_length	RECORD_R001_ROUGHNESS.docx	5	7	2	text		1	2026-08-19 10:29:56.819659+08	\N
1085	1	static	sampling_count	RECORD_R001_ROUGHNESS.docx	5	8	1	checkbox		2	2026-08-19 10:29:56.819659+08	\N
1086	1	static	evaluation_length	RECORD_R001_ROUGHNESS.docx	5	9	2	text		3	2026-08-19 10:29:56.819659+08	\N
1087	1	static	surface_confirm	RECORD_R001_ROUGHNESS.docx	7	1	1	checkbox		4	2026-08-19 10:29:56.819659+08	\N
1088	1	static	mean	RECORD_R001_ROUGHNESS.docx	8	1	1	text		5	2026-08-19 10:29:56.819659+08	\N
1090	3	static	panel_no	RECORD_R005_XRAY.docx	3	2	7	checkbox		0	2026-08-19 11:26:54.051153+08	\N
1091	3	static	density_meter_no	RECORD_R005_XRAY.docx	3	4	7	checkbox		1	2026-08-19 11:26:54.051153+08	\N
1092	3	static	density_nominal	RECORD_R005_XRAY.docx	3	5	7	checkbox		2	2026-08-19 11:26:54.051153+08	\N
1093	3	static	density_measured_3	RECORD_R005_XRAY.docx	3	5	7	checkbox		3	2026-08-19 11:26:54.051153+08	\N
1089	2	static	fixture_no	RECORD_R004_MC_CRACK.docx	3	1	3	checkbox		0	2026-08-19 10:50:59.714217+08	\N
1078	14	static	solution_change_24h	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	5	2	text		17	2026-08-16 15:39:41.341724+08	\N
1079	14	static	solution_change_48h	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	6	2	text		18	2026-08-16 15:39:41.341724+08	\N
1080	14	static	tarnish_product	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	7	1	text		19	2026-08-16 15:39:41.341724+08	\N
1081	14	static	tarnish_verdict	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	9	4	1	checkbox		20	2026-08-16 15:39:41.341724+08	\N
1082	14	static	total_duration	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	7	2	text		21	2026-08-16 15:39:41.341724+08	\N
612	17	static	calculation_standard	RECORD_R001_ROUGHNESS.docx	5	1	2	raw		0	2026-08-16 15:39:41.341724+08	\N
613	17	static	calculation_standard_ok	RECORD_R001_ROUGHNESS.docx	5	1	3	checkbox		1	2026-08-16 15:39:41.341724+08	\N
614	17	static	clean_ok	RECORD_R001_ROUGHNESS.docx	2	4	4	checkbox		2	2026-08-16 15:39:41.341724+08	\N
615	17	static	clean_status	RECORD_R001_ROUGHNESS.docx	2	4	2	checkbox		3	2026-08-16 15:39:41.341724+08	\N
616	17	static	cutoff_filter	RECORD_R001_ROUGHNESS.docx	5	3	2	raw		4	2026-08-16 15:39:41.341724+08	\N
617	17	static	cutoff_filter_ok	RECORD_R001_ROUGHNESS.docx	5	3	3	checkbox		5	2026-08-16 15:39:41.341724+08	\N
618	17	static	deviation_affects_result	RECORD_R001_ROUGHNESS.docx	9	1	5	checkbox		6	2026-08-16 15:39:41.341724+08	\N
619	17	static	deviation_record	RECORD_R001_ROUGHNESS.docx	9	1	2	raw		7	2026-08-16 15:39:41.341724+08	\N
620	17	static	dust_ok	RECORD_R001_ROUGHNESS.docx	2	5	4	checkbox		8	2026-08-16 15:39:41.341724+08	\N
621	17	static	dust_status	RECORD_R001_ROUGHNESS.docx	2	5	2	checkbox		9	2026-08-16 15:39:41.341724+08	\N
622	17	static	env_humidity_ok	RECORD_R001_ROUGHNESS.docx	2	2	4	checkbox		10	2026-08-16 15:39:41.341724+08	\N
623	17	static	env_temp_ok	RECORD_R001_ROUGHNESS.docx	2	1	4	checkbox		11	2026-08-16 15:39:41.341724+08	\N
624	17	static	evaluation_length_ok	RECORD_R001_ROUGHNESS.docx	5	7	3	checkbox		12	2026-08-16 15:39:41.341724+08	\N
625	17	static	evaluation_length_ok2	RECORD_R001_ROUGHNESS.docx	5	9	3	checkbox		13	2026-08-16 15:39:41.341724+08	\N
626	17	static	evaluation_length_value	RECORD_R001_ROUGHNESS.docx	5	7	2	raw		14	2026-08-16 15:39:41.341724+08	\N
627	17	static	evaluation_length_value2	RECORD_R001_ROUGHNESS.docx	5	9	2	raw		15	2026-08-16 15:39:41.341724+08	\N
628	17	static	final_conclusion	RECORD_R001_ROUGHNESS.docx	8	6	1	text		16	2026-08-16 15:39:41.341724+08	\N
629	17	static	final_verdict	RECORD_R001_ROUGHNESS.docx	8	5	1	checkbox		17	2026-08-16 15:39:41.341724+08	\N
630	17	static	fixture_conclusion	RECORD_R001_ROUGHNESS.docx	4	2	3	checkbox		18	2026-08-16 15:39:41.341724+08	\N
631	17	static	fixture_record	RECORD_R001_ROUGHNESS.docx	4	2	2	checkbox		19	2026-08-16 15:39:41.341724+08	\N
632	17	static	humidity_after	RECORD_R001_ROUGHNESS.docx	2	2	3	text		20	2026-08-16 15:39:41.341724+08	\N
633	17	static	humidity_before	RECORD_R001_ROUGHNESS.docx	2	2	2	text		21	2026-08-16 15:39:41.341724+08	\N
634	17	static	interference_col2	RECORD_R001_ROUGHNESS.docx	2	3	2	checkbox		22	2026-08-16 15:39:41.341724+08	\N
635	17	static	interference_col3	RECORD_R001_ROUGHNESS.docx	2	3	3	checkbox		23	2026-08-16 15:39:41.341724+08	\N
636	17	static	interference_ok	RECORD_R001_ROUGHNESS.docx	2	3	4	checkbox		24	2026-08-16 15:39:41.341724+08	\N
637	17	static	lambda_s	RECORD_R001_ROUGHNESS.docx	5	2	2	raw		25	2026-08-16 15:39:41.341724+08	\N
638	17	static	lambda_s_ok	RECORD_R001_ROUGHNESS.docx	5	2	3	checkbox		26	2026-08-16 15:39:41.341724+08	\N
639	17	static	measurement_direction	RECORD_R001_ROUGHNESS.docx	5	10	2	raw		27	2026-08-16 15:39:41.341724+08	\N
640	17	static	measurement_direction_ok	RECORD_R001_ROUGHNESS.docx	5	10	3	checkbox		28	2026-08-16 15:39:41.341724+08	\N
641	17	static	measurement_range	RECORD_R001_ROUGHNESS.docx	5	5	2	raw		29	2026-08-16 15:39:41.341724+08	\N
642	17	static	measurement_range_ok	RECORD_R001_ROUGHNESS.docx	5	5	3	checkbox		30	2026-08-16 15:39:41.341724+08	\N
643	17	static	overall_conclusion	RECORD_R001_ROUGHNESS.docx	4	6	3	checkbox		31	2026-08-16 15:39:41.341724+08	\N
644	17	static	overall_record	RECORD_R001_ROUGHNESS.docx	4	6	2	checkbox		32	2026-08-16 15:39:41.341724+08	\N
645	17	static	platform_conclusion	RECORD_R001_ROUGHNESS.docx	4	1	3	checkbox		33	2026-08-16 15:39:41.341724+08	\N
646	17	static	platform_record	RECORD_R001_ROUGHNESS.docx	4	1	2	checkbox		34	2026-08-16 15:39:41.341724+08	\N
647	17	static	probe_conclusion	RECORD_R001_ROUGHNESS.docx	4	5	3	checkbox		35	2026-08-16 15:39:41.341724+08	\N
648	17	static	probe_record	RECORD_R001_ROUGHNESS.docx	4	5	2	checkbox		36	2026-08-16 15:39:41.341724+08	\N
649	17	static	repeat_conclusion	RECORD_R001_ROUGHNESS.docx	4	4	3	checkbox		37	2026-08-16 15:39:41.341724+08	\N
650	17	static	repeat_record	RECORD_R001_ROUGHNESS.docx	4	4	2	raw		38	2026-08-16 15:39:41.341724+08	\N
651	17	static	sampling_count_ok	RECORD_R001_ROUGHNESS.docx	5	8	3	checkbox		39	2026-08-16 15:39:41.341724+08	\N
652	17	static	sampling_count_select	RECORD_R001_ROUGHNESS.docx	5	8	1	checkbox		40	2026-08-16 15:39:41.341724+08	\N
653	17	static	sampling_count_value	RECORD_R001_ROUGHNESS.docx	5	8	2	raw		41	2026-08-16 15:39:41.341724+08	\N
654	17	static	sampling_length_ok	RECORD_R001_ROUGHNESS.docx	5	6	3	checkbox		42	2026-08-16 15:39:41.341724+08	\N
655	17	static	sampling_length_select	RECORD_R001_ROUGHNESS.docx	5	6	1	checkbox		43	2026-08-16 15:39:41.341724+08	\N
656	17	static	sampling_length_value	RECORD_R001_ROUGHNESS.docx	5	6	2	raw		44	2026-08-16 15:39:41.341724+08	\N
657	17	static	shape_removal	RECORD_R001_ROUGHNESS.docx	5	4	2	raw		45	2026-08-16 15:39:41.341724+08	\N
658	17	static	shape_removal_ok	RECORD_R001_ROUGHNESS.docx	5	4	3	checkbox		46	2026-08-16 15:39:41.341724+08	\N
659	17	static	standard_block_conclusion	RECORD_R001_ROUGHNESS.docx	4	3	3	checkbox		47	2026-08-16 15:39:41.341724+08	\N
660	17	static	standard_block_record	RECORD_R001_ROUGHNESS.docx	4	3	2	raw		48	2026-08-16 15:39:41.341724+08	\N
661	17	static	statistics_failed	RECORD_R001_ROUGHNESS.docx	8	2	1	checkbox		49	2026-08-16 15:39:41.341724+08	\N
662	17	static	statistics_minmax	RECORD_R001_ROUGHNESS.docx	8	1	1	raw		50	2026-08-16 15:39:41.341724+08	\N
663	17	static	temperature_after	RECORD_R001_ROUGHNESS.docx	2	1	3	text		51	2026-08-16 15:39:41.341724+08	\N
664	17	static	temperature_before	RECORD_R001_ROUGHNESS.docx	2	1	2	text		52	2026-08-16 15:39:41.341724+08	\N
665	17	static	three_length_applicable	RECORD_R001_ROUGHNESS.docx	6	0	2	checkbox		53	2026-08-16 15:39:41.341724+08	\N
666	17	static	three_length_conclusion	RECORD_R001_ROUGHNESS.docx	8	3	1	checkbox		54	2026-08-16 15:39:41.341724+08	\N
667	17	static	three_length_not_applicable	RECORD_R001_ROUGHNESS.docx	6	0	1	checkbox		55	2026-08-16 15:39:41.341724+08	\N
687	19	static	density_mean	RECORD_R005_XRAY.docx	4	1	5	text		0	2026-08-16 15:39:41.341724+08	\N
688	19	static	density_verdict	RECORD_R005_XRAY.docx	4	1	7	checkbox		1	2026-08-16 15:39:41.341724+08	\N
689	19	static	end_time	RECORD_R005_XRAY.docx	2	0	3	text		2	2026-08-16 15:39:41.341724+08	\N
690	19	static	humidity_before	RECORD_R005_XRAY.docx	2	2	1	text		3	2026-08-16 15:39:41.341724+08	\N
691	19	static	humidity_ok	RECORD_R005_XRAY.docx	2	2	5	checkbox		4	2026-08-16 15:39:41.341724+08	\N
692	19	static	image_no_t7	RECORD_R005_XRAY.docx	7	0	6	text		5	2026-08-16 15:39:41.341724+08	\N
693	19	static	operator_t2	RECORD_R005_XRAY.docx	2	0	5	text		6	2026-08-16 15:39:41.341724+08	\N
694	19	static	operator_t7	RECORD_R005_XRAY.docx	7	1	6	text		7	2026-08-16 15:39:41.341724+08	\N
695	19	static	reviewer_t7	RECORD_R005_XRAY.docx	7	1	10	text		8	2026-08-16 15:39:41.341724+08	\N
696	19	static	sample_no_t7	RECORD_R005_XRAY.docx	7	0	2	text		9	2026-08-16 15:39:41.341724+08	\N
697	19	static	software	RECORD_R005_XRAY.docx	7	1	2	text		10	2026-08-16 15:39:41.341724+08	\N
698	19	static	start_time	RECORD_R005_XRAY.docx	2	0	1	text		11	2026-08-16 15:39:41.341724+08	\N
699	19	static	temperature_before	RECORD_R005_XRAY.docx	2	1	1	text		12	2026-08-16 15:39:41.341724+08	\N
700	19	static	temperature_ok	RECORD_R005_XRAY.docx	2	1	5	checkbox		13	2026-08-16 15:39:41.341724+08	\N
701	19	static	test_date	RECORD_R005_XRAY.docx	7	0	10	text		14	2026-08-16 15:39:41.341724+08	\N
702	21	static	alpha_mean	RECORD_R007_CTE.docx	8	1	1	text		0	2026-08-16 15:39:41.341724+08	\N
703	21	static	attachment_ref_t8	RECORD_R007_CTE.docx	8	2	3	text		1	2026-08-16 15:39:41.341724+08	\N
704	21	static	delta_l_max	RECORD_R007_CTE.docx	8	2	1	text		2	2026-08-16 15:39:41.341724+08	\N
705	21	static	final_verdict	RECORD_R007_CTE.docx	8	0	1	checkbox		3	2026-08-16 15:39:41.341724+08	\N
706	21	static	humidity_before	RECORD_R007_CTE.docx	1	2	2	text		4	2026-08-16 15:39:41.341724+08	\N
707	21	static	temperature_before	RECORD_R007_CTE.docx	1	1	2	text		5	2026-08-16 15:39:41.341724+08	\N
708	21	static	temperature_range	RECORD_R007_CTE.docx	8	1	3	raw		6	2026-08-16 15:39:41.341724+08	\N
709	22	static	appearance_check	RECORD_R009_THERMAL_SHOCK.docx	4	1	2	checkbox		0	2026-08-16 15:39:41.341724+08	\N
710	22	static	chipping_count	RECORD_R009_THERMAL_SHOCK.docx	9	1	3	text		1	2026-08-16 15:39:41.341724+08	\N
711	22	static	container_no	RECORD_R009_THERMAL_SHOCK.docx	6	1	0	text		2	2026-08-16 15:39:41.341724+08	\N
712	22	static	cooling_record	RECORD_R009_THERMAL_SHOCK.docx	7	3	2	text		3	2026-08-16 15:39:41.341724+08	\N
713	22	static	cooling_temp_record	RECORD_R009_THERMAL_SHOCK.docx	7	1	2	text		4	2026-08-16 15:39:41.341724+08	\N
714	22	static	crack_count	RECORD_R009_THERMAL_SHOCK.docx	9	1	1	text		5	2026-08-16 15:39:41.341724+08	\N
715	22	static	env_humidity_ok	RECORD_R009_THERMAL_SHOCK.docx	1	2	4	checkbox		6	2026-08-16 15:39:41.341724+08	\N
716	22	static	env_temp_ok	RECORD_R009_THERMAL_SHOCK.docx	1	1	4	checkbox		7	2026-08-16 15:39:41.341724+08	\N
717	22	static	final_conclusion	RECORD_R009_THERMAL_SHOCK.docx	9	4	1	checkbox		8	2026-08-16 15:39:41.341724+08	\N
718	22	static	final_verdict	RECORD_R009_THERMAL_SHOCK.docx	9	3	3	checkbox		9	2026-08-16 15:39:41.341724+08	\N
719	22	static	first_heating_interval	RECORD_R009_THERMAL_SHOCK.docx	6	1	2	text		10	2026-08-16 15:39:41.341724+08	\N
720	22	static	first_heating_record	RECORD_R009_THERMAL_SHOCK.docx	4	3	2	text		11	2026-08-16 15:39:41.341724+08	\N
721	22	static	fracture_count	RECORD_R009_THERMAL_SHOCK.docx	9	2	1	text		12	2026-08-16 15:39:41.341724+08	\N
722	22	static	humidity_after	RECORD_R009_THERMAL_SHOCK.docx	1	2	3	text		13	2026-08-16 15:39:41.341724+08	\N
723	22	static	humidity_before	RECORD_R009_THERMAL_SHOCK.docx	1	2	2	text		14	2026-08-16 15:39:41.341724+08	\N
724	22	static	ice_bath_record	RECORD_R009_THERMAL_SHOCK.docx	4	4	2	text		15	2026-08-16 15:39:41.341724+08	\N
725	22	static	ice_immersion_record	RECORD_R009_THERMAL_SHOCK.docx	4	7	2	text		16	2026-08-16 15:39:41.341724+08	\N
726	22	static	ice_water_record	RECORD_R009_THERMAL_SHOCK.docx	4	5	2	text		17	2026-08-16 15:39:41.341724+08	\N
727	22	static	illumination_col2	RECORD_R009_THERMAL_SHOCK.docx	1	3	2	text		18	2026-08-16 15:39:41.341724+08	\N
728	22	static	illumination_col3	RECORD_R009_THERMAL_SHOCK.docx	1	3	3	text		19	2026-08-16 15:39:41.341724+08	\N
729	22	static	illumination_ok	RECORD_R009_THERMAL_SHOCK.docx	1	3	4	checkbox		20	2026-08-16 15:39:41.341724+08	\N
730	22	static	illumination_record	RECORD_R009_THERMAL_SHOCK.docx	7	4	2	text		21	2026-08-16 15:39:41.341724+08	\N
731	22	static	immersion_interval	RECORD_R009_THERMAL_SHOCK.docx	6	1	4	text		22	2026-08-16 15:39:41.341724+08	\N
732	22	static	inspector_record	RECORD_R009_THERMAL_SHOCK.docx	7	5	2	text		23	2026-08-16 15:39:41.341724+08	\N
733	22	static	oven_temperature_record	RECORD_R009_THERMAL_SHOCK.docx	4	2	2	text		24	2026-08-16 15:39:41.341724+08	\N
734	22	static	sample_count	RECORD_R009_THERMAL_SHOCK.docx	6	1	1	text		25	2026-08-16 15:39:41.341724+08	\N
735	22	static	second_heating_interval	RECORD_R009_THERMAL_SHOCK.docx	6	1	5	text		26	2026-08-16 15:39:41.341724+08	\N
736	22	static	second_heating_record	RECORD_R009_THERMAL_SHOCK.docx	4	8	2	text		27	2026-08-16 15:39:41.341724+08	\N
737	22	static	surface_temp_record	RECORD_R009_THERMAL_SHOCK.docx	7	2	2	text		28	2026-08-16 15:39:41.341724+08	\N
738	22	static	temperature_after	RECORD_R009_THERMAL_SHOCK.docx	1	1	3	text		29	2026-08-16 15:39:41.341724+08	\N
739	22	static	temperature_before	RECORD_R009_THERMAL_SHOCK.docx	1	1	2	text		30	2026-08-16 15:39:41.341724+08	\N
740	22	static	total_count	RECORD_R009_THERMAL_SHOCK.docx	9	0	1	text		31	2026-08-16 15:39:41.341724+08	\N
741	22	static	total_count_2	RECORD_R009_THERMAL_SHOCK.docx	9	0	3	text		32	2026-08-16 15:39:41.341724+08	\N
742	22	static	transfer_interval	RECORD_R009_THERMAL_SHOCK.docx	6	1	3	text		33	2026-08-16 15:39:41.341724+08	\N
743	22	static	transfer_time_record	RECORD_R009_THERMAL_SHOCK.docx	4	6	2	text		34	2026-08-16 15:39:41.341724+08	\N
744	23	static	attachment_ref_t7	RECORD_R010_BENDING.docx	7	0	1	text		0	2026-08-16 15:39:41.341724+08	\N
745	23	static	has_attachment_a	RECORD_R010_BENDING.docx	7	1	1	checkbox		1	2026-08-16 15:39:41.341724+08	\N
746	23	static	has_attachment_b	RECORD_R010_BENDING.docx	7	1	3	checkbox		2	2026-08-16 15:39:41.341724+08	\N
747	23	static	overall_verdict	RECORD_R010_BENDING.docx	4	7	0	checkbox		3	2026-08-16 15:39:41.341724+08	\N
748	24	static	indent_method	RECORD_R011_VICKERS.docx	3	1	1	checkbox		0	2026-08-16 15:39:41.341724+08	\N
749	24	static	perpendicularity	RECORD_R011_VICKERS.docx	2	5	5	checkbox		1	2026-08-16 15:39:41.341724+08	\N
750	24	static	report_exported	RECORD_R011_VICKERS.docx	3	2	3	checkbox		2	2026-08-16 15:39:41.341724+08	\N
751	24	static	report_exported_ok	RECORD_R011_VICKERS.docx	3	2	5	checkbox		3	2026-08-16 15:39:41.341724+08	\N
752	24	static	standard_block_due	RECORD_R011_VICKERS.docx	2	1	5	text		4	2026-08-16 15:39:41.341724+08	\N
753	24	static	std_reading_1	RECORD_R011_VICKERS.docx	2	2	3	text		5	2026-08-16 15:39:41.341724+08	\N
754	24	static	std_reading_2	RECORD_R011_VICKERS.docx	2	2	5	text		6	2026-08-16 15:39:41.341724+08	\N
755	24	static	std_reading_3	RECORD_R011_VICKERS.docx	2	3	1	text		7	2026-08-16 15:39:41.341724+08	\N
756	24	static	std_reading_mean	RECORD_R011_VICKERS.docx	2	3	3	text		8	2026-08-16 15:39:41.341724+08	\N
757	24	static	std_result	RECORD_R011_VICKERS.docx	2	3	5	checkbox		9	2026-08-16 15:39:41.341724+08	\N
758	24	static	surface_condition	RECORD_R011_VICKERS.docx	2	5	1	checkbox		10	2026-08-16 15:39:41.341724+08	\N
759	24	static	surface_verdict	RECORD_R011_VICKERS.docx	2	4	5	checkbox		11	2026-08-16 15:39:41.341724+08	\N
760	25	static	calibration_record	RECORD_R013_THICKNESS.docx	2	3	2	text		0	2026-08-16 15:39:41.341724+08	\N
761	25	static	design_file_no	RECORD_R013_THICKNESS.docx	0	7	5	text		1	2026-08-16 15:39:41.341724+08	\N
762	25	static	magnification_record	RECORD_R013_THICKNESS.docx	2	1	2	text		2	2026-08-16 15:39:41.341724+08	\N
763	25	static	preheat_record	RECORD_R013_THICKNESS.docx	2	2	2	text		3	2026-08-16 15:39:41.341724+08	\N
764	25	static	production_date	RECORD_R013_THICKNESS.docx	0	7	3	text		4	2026-08-16 15:39:41.341724+08	\N
765	25	static	sample_batch	RECORD_R013_THICKNESS.docx	0	7	1	text		5	2026-08-16 15:39:41.341724+08	\N
766	26	static	attachment_ref_t7	RECORD_R012_COLOR_STABILITY.docx	7	2	1	text		0	2026-08-16 15:39:41.341724+08	\N
767	26	static	background	RECORD_R012_COLOR_STABILITY.docx	9	2	1	checkbox		1	2026-08-16 15:39:41.341724+08	\N
768	26	static	background_ok	RECORD_R012_COLOR_STABILITY.docx	9	2	3	checkbox		2	2026-08-16 15:39:41.341724+08	\N
769	26	static	d65_illuminance	RECORD_R012_COLOR_STABILITY.docx	9	1	3	text		3	2026-08-16 15:39:41.341724+08	\N
770	26	static	device_status	RECORD_R012_COLOR_STABILITY.docx	5	7	2	checkbox		4	2026-08-16 15:39:41.341724+08	\N
771	26	static	exposure_end	RECORD_R012_COLOR_STABILITY.docx	7	0	3	text		5	2026-08-16 15:39:41.341724+08	\N
772	26	static	exposure_ok	RECORD_R012_COLOR_STABILITY.docx	7	1	3	checkbox		6	2026-08-16 15:39:41.341724+08	\N
773	26	static	exposure_start	RECORD_R012_COLOR_STABILITY.docx	7	0	1	text		7	2026-08-16 15:39:41.341724+08	\N
774	26	static	exposure_time	RECORD_R012_COLOR_STABILITY.docx	7	1	1	text		8	2026-08-16 15:39:41.341724+08	\N
775	26	static	exposure_time_record	RECORD_R012_COLOR_STABILITY.docx	5	5	2	text		9	2026-08-16 15:39:41.341724+08	\N
776	26	static	filter_hours	RECORD_R012_COLOR_STABILITY.docx	4	1	3	text		10	2026-08-16 15:39:41.341724+08	\N
777	26	static	filter_no	RECORD_R012_COLOR_STABILITY.docx	4	1	1	text		11	2026-08-16 15:39:41.341724+08	\N
778	26	static	final_verdict	RECORD_R012_COLOR_STABILITY.docx	11	13	7	checkbox		12	2026-08-16 15:39:41.341724+08	\N
779	26	static	handling_status	RECORD_R012_COLOR_STABILITY.docx	9	0	3	checkbox		13	2026-08-16 15:39:41.341724+08	\N
780	26	static	has_attachment_a	RECORD_R012_COLOR_STABILITY.docx	7	3	1	checkbox		14	2026-08-16 15:39:41.341724+08	\N
781	26	static	has_attachment_b	RECORD_R012_COLOR_STABILITY.docx	7	3	3	checkbox		15	2026-08-16 15:39:41.341724+08	\N
782	26	static	humidity_before	RECORD_R012_COLOR_STABILITY.docx	1	0	5	text		16	2026-08-16 15:39:41.341724+08	\N
783	26	static	lamp_box_ready	RECORD_R012_COLOR_STABILITY.docx	9	1	1	checkbox		17	2026-08-16 15:39:41.341724+08	\N
784	26	static	lamp_calibrated	RECORD_R012_COLOR_STABILITY.docx	4	2	3	checkbox		18	2026-08-16 15:39:41.341724+08	\N
785	26	static	lamp_history	RECORD_R012_COLOR_STABILITY.docx	4	3	3	checkbox		19	2026-08-16 15:39:41.341724+08	\N
786	26	static	lamp_hours	RECORD_R012_COLOR_STABILITY.docx	4	0	3	text		20	2026-08-16 15:39:41.341724+08	\N
787	26	static	lamp_no	RECORD_R012_COLOR_STABILITY.docx	4	0	1	text		21	2026-08-16 15:39:41.341724+08	\N
788	26	static	lightbox_clean	RECORD_R012_COLOR_STABILITY.docx	1	2	5	checkbox		22	2026-08-16 15:39:41.341724+08	\N
789	26	static	lightbox_confirmed	RECORD_R012_COLOR_STABILITY.docx	1	3	5	checkbox		23	2026-08-16 15:39:41.341724+08	\N
790	26	static	lightbox_type	RECORD_R012_COLOR_STABILITY.docx	1	2	1	checkbox		24	2026-08-16 15:39:41.341724+08	\N
791	26	static	observation_conditions	RECORD_R012_COLOR_STABILITY.docx	9	4	1	checkbox		25	2026-08-16 15:39:41.341724+08	\N
792	26	static	observation_date	RECORD_R012_COLOR_STABILITY.docx	9	4	3	text		26	2026-08-16 15:39:41.341724+08	\N
793	26	static	observation_distance	RECORD_R012_COLOR_STABILITY.docx	9	3	1	text		27	2026-08-16 15:39:41.341724+08	\N
794	26	static	overall_verdict	RECORD_R012_COLOR_STABILITY.docx	11	13	2	checkbox		28	2026-08-16 15:39:41.341724+08	\N
795	26	static	sample_handling	RECORD_R012_COLOR_STABILITY.docx	9	0	1	checkbox		29	2026-08-16 15:39:41.341724+08	\N
796	26	static	sample_illuminance	RECORD_R012_COLOR_STABILITY.docx	5	3	2	text		30	2026-08-16 15:39:41.341724+08	\N
797	26	static	sample_placement	RECORD_R012_COLOR_STABILITY.docx	5	6	2	checkbox		31	2026-08-16 15:39:41.341724+08	\N
798	26	static	single_observation_time	RECORD_R012_COLOR_STABILITY.docx	9	3	3	text		32	2026-08-16 15:39:41.341724+08	\N
799	26	static	source_type	RECORD_R012_COLOR_STABILITY.docx	5	1	2	checkbox		33	2026-08-16 15:39:41.341724+08	\N
800	26	static	temperature_before	RECORD_R012_COLOR_STABILITY.docx	1	0	1	text		34	2026-08-16 15:39:41.341724+08	\N
801	26	static	trace_ref	RECORD_R012_COLOR_STABILITY.docx	7	2	3	text		35	2026-08-16 15:39:41.341724+08	\N
802	26	static	water_distance	RECORD_R012_COLOR_STABILITY.docx	5	4	2	text		36	2026-08-16 15:39:41.341724+08	\N
803	26	static	water_temp_record	RECORD_R012_COLOR_STABILITY.docx	5	2	2	text		37	2026-08-16 15:39:41.341724+08	\N
804	27	static	attachment_ref_t10	R014_定制式固定义齿检验_CMA原始记录表.docx	10	6	1	text		0	2026-08-16 15:39:41.341724+08	\N
805	27	static	final_verdict	R014_定制式固定义齿检验_CMA原始记录表.docx	10	5	1	checkbox		1	2026-08-16 15:39:41.341724+08	\N
806	27	static	porosity_result	R014_定制式固定义齿检验_CMA原始记录表.docx	10	1	1	checkbox		2	2026-08-16 15:39:41.341724+08	\N
807	27	static	roughness_result	R014_定制式固定义齿检验_CMA原始记录表.docx	10	4	1	checkbox		3	2026-08-16 15:39:41.341724+08	\N
808	28	static	attachment_ref_t9a	R015_定制式活动义齿检验_CMA原始记录表.docx	9	2	1	text		0	2026-08-16 15:39:41.341724+08	\N
809	28	static	attachment_ref_t9b	R015_定制式活动义齿检验_CMA原始记录表.docx	9	6	1	text		1	2026-08-16 15:39:41.341724+08	\N
810	28	static	cutting_device_no	R015_定制式活动义齿检验_CMA原始记录表.docx	10	1	2	text		2	2026-08-16 15:39:41.341724+08	\N
811	28	static	final_conclusion	R015_定制式活动义齿检验_CMA原始记录表.docx	15	1	1	checkbox		3	2026-08-16 15:39:41.341724+08	\N
812	28	static	final_no	R015_定制式活动义齿检验_CMA原始记录表.docx	15	4	1	checkbox		4	2026-08-16 15:39:41.341724+08	\N
813	28	static	inner_angle	R015_定制式活动义齿检验_CMA原始记录表.docx	10	3	3	text		5	2026-08-16 15:39:41.341724+08	\N
814	28	static	iqi_no	R015_定制式活动义齿检验_CMA原始记录表.docx	9	3	1	text		6	2026-08-16 15:39:41.341724+08	\N
815	28	static	lower_no_pore_faces	R015_定制式活动义齿检验_CMA原始记录表.docx	11	2	7	text		7	2026-08-16 15:39:41.341724+08	\N
816	28	static	outer_angle	R015_定制式活动义齿检验_CMA原始记录表.docx	10	2	3	text		8	2026-08-16 15:39:41.341724+08	\N
817	28	static	porosity_lower	R015_定制式活动义齿检验_CMA原始记录表.docx	11	2	8	checkbox		9	2026-08-16 15:39:41.341724+08	\N
818	28	static	porosity_upper	R015_定制式活动义齿检验_CMA原始记录表.docx	11	1	8	checkbox		10	2026-08-16 15:39:41.341724+08	\N
819	28	static	same_vertical	R015_定制式活动义齿检验_CMA原始记录表.docx	10	4	3	checkbox		11	2026-08-16 15:39:41.341724+08	\N
820	28	static	termination_inner	R015_定制式活动义齿检验_CMA原始记录表.docx	10	3	4	checkbox		12	2026-08-16 15:39:41.341724+08	\N
821	28	static	termination_outer	R015_定制式活动义齿检验_CMA原始记录表.docx	10	2	4	checkbox		13	2026-08-16 15:39:41.341724+08	\N
822	28	static	termination_vertical	R015_定制式活动义齿检验_CMA原始记录表.docx	10	4	4	checkbox		14	2026-08-16 15:39:41.341724+08	\N
823	28	static	upper_no_pore_faces	R015_定制式活动义齿检验_CMA原始记录表.docx	11	1	7	text		15	2026-08-16 15:39:41.341724+08	\N
824	28	static	xray_conclusion	R015_定制式活动义齿检验_CMA原始记录表.docx	9	10	1	checkbox		16	2026-08-16 15:39:41.341724+08	\N
825	29	static	attachment_ref_t10	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	10	4	1	text		0	2026-08-16 15:39:41.341724+08	\N
826	29	static	auto_calc_check	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	4	4	5	checkbox		1	2026-08-16 15:39:41.341724+08	\N
827	29	static	balance_calibration	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	2	0	7	checkbox		2	2026-08-16 15:39:41.341724+08	\N
828	29	static	declared_density	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	10	1	3	text		3	2026-08-16 15:39:41.341724+08	\N
829	29	static	declared_source	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	10	1	1	text		4	2026-08-16 15:39:41.341724+08	\N
830	29	static	density_verdict	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	10	3	1	checkbox		5	2026-08-16 15:39:41.341724+08	\N
831	29	static	overall_mean	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	7	7	3	text		6	2026-08-16 15:39:41.341724+08	\N
832	29	static	overall_mean_1dp	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	7	7	8	text		7	2026-08-16 15:39:41.341724+08	\N
833	29	static	overall_verdict	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	7	7	10	checkbox		8	2026-08-16 15:39:41.341724+08	\N
834	29	static	system_check	R016_激光选区熔化金属材料密度试验_CMA原始记录表.docx	3	6	6	checkbox		9	2026-08-16 15:39:41.341724+08	\N
835	30	static	attachment_ref_t12	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	12	4	3	text		0	2026-08-16 15:39:41.341724+08	\N
836	30	static	bath_status	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	8	2	checkbox		1	2026-08-16 15:39:41.341724+08	\N
837	30	static	bath_temperature	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	2	2	text		2	2026-08-16 15:39:41.341724+08	\N
838	30	static	bath_volume	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	1	2	text		3	2026-08-16 15:39:41.341724+08	\N
839	30	static	color_change_verdict	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	9	1	1	checkbox		4	2026-08-16 15:39:41.341724+08	\N
840	30	static	control_color_change	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	5	2	text		5	2026-08-16 15:39:41.341724+08	\N
841	30	static	cycle_immersion_seconds	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	3	2	text		6	2026-08-16 15:39:41.341724+08	\N
842	30	static	final_conclusion	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	12	2	1	checkbox		7	2026-08-16 15:39:41.341724+08	\N
843	30	static	immersed_color_change	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	5	1	text		8	2026-08-16 15:39:41.341724+08	\N
844	30	static	immersed_sample_no	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	8	1	0	text		9	2026-08-16 15:39:41.341724+08	\N
845	30	static	observation_distance	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	3	3	text		10	2026-08-16 15:39:41.341724+08	\N
846	30	static	observation_illuminance	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	2	3	text		11	2026-08-16 15:39:41.341724+08	\N
847	30	static	reflectance_change	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	6	1	text		12	2026-08-16 15:39:41.341724+08	\N
848	30	static	reflectance_verdict	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	9	3	1	text		13	2026-08-16 15:39:41.341724+08	\N
849	30	static	removal_ease	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	8	1	3	checkbox		14	2026-08-16 15:39:41.341724+08	\N
850	30	static	removal_ease_verdict	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	9	2	1	checkbox		15	2026-08-16 15:39:41.341724+08	\N
851	30	static	result_valid	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	12	1	1	checkbox		16	2026-08-16 15:39:41.341724+08	\N
852	30	static	solution_change_24h	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	5	2	text		17	2026-08-16 15:39:41.341724+08	\N
853	30	static	solution_change_48h	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	6	2	text		18	2026-08-16 15:39:41.341724+08	\N
854	30	static	tarnish_product	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	7	7	1	text		19	2026-08-16 15:39:41.341724+08	\N
855	30	static	tarnish_verdict	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	9	4	1	checkbox		20	2026-08-16 15:39:41.341724+08	\N
856	30	static	total_duration	R017_金属材料抗晦暗性能试验_CMA原始记录表.docx	5	7	2	text		21	2026-08-16 15:39:41.341724+08	\N
\.


--
-- Data for Name: template_versions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.template_versions (experiment, doc_type, file_name, version, effective_date, status, created_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (username, display_name, password_hash, role, enabled, created_at) FROM stdin;
admin	赵衡	$2b$12$lp3XQLFf.BWTvuWFkLamD.3MP9X.cNz8XjwqVFC33g8Hjc1KpG6Y6	管理员	t	2026-08-12 12:23:36.165902+08
receiver	韩丹	$2b$12$mWEIZz0.TMZ3PumM6I2og.YBLvfF357M1OyAzBAnvTaEh.Wos0d3S	样品管理员	t	2026-08-12 12:23:36.165902+08
liuhong_test	刘红	$2b$12$jyN59QZqY97U0zFRrIcLbO4ZaeExe6hcebi/T/4Rkl2Wykm0o57LS	实验员	t	2026-08-12 12:23:36.165902+08
liuhong_review	刘红	$2b$12$x2AsxrtVtpu4WRhxrlvP7uTim0daGso2m..DnTEIje714vv/0PKzy	复核员	t	2026-08-12 12:23:36.165902+08
lihongli_test	李红丽	$2b$12$9V7UZuDJMJjoXtWwHL.Ab.IJy6oZq48GTFfF8gWiCGlGK68ksHpFy	实验员	t	2026-08-12 12:23:36.165902+08
lihongli_review	李红丽	$2b$12$mmCkmiR.F1CAsp4j5W6ozu21/iSguFovH4cCd685eSxZ6t3OJwwpO	复核员	t	2026-08-12 12:23:36.165902+08
quality	刘丽	$2b$12$Iiuf6jwCLmZKA8YhKWFdk.XV0gguBgCC5zd480YW35jUZSS.7Tqh6	质量负责人	t	2026-08-12 12:23:36.165902+08
\.


--
-- Name: attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.attachments_id_seq', 6, true);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 338, true);


--
-- Name: document_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.document_versions_id_seq', 1, false);


--
-- Name: equipment_incident_actions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.equipment_incident_actions_id_seq', 1, false);


--
-- Name: experiment_config_columns_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.experiment_config_columns_id_seq', 1411, true);


--
-- Name: experiment_config_fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.experiment_config_fields_id_seq', 4812, true);


--
-- Name: experiment_config_photo_checkpoints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.experiment_config_photo_checkpoints_id_seq', 651, true);


--
-- Name: experiment_config_prechecks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.experiment_config_prechecks_id_seq', 1010, true);


--
-- Name: experiment_config_validation_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.experiment_config_validation_rules_id_seq', 1, false);


--
-- Name: experiment_config_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.experiment_config_versions_id_seq', 30, true);


--
-- Name: experiment_standards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.experiment_standards_id_seq', 4, true);


--
-- Name: modification_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.modification_logs_id_seq', 164, true);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- Name: objection_actions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.objection_actions_id_seq', 1, false);


--
-- Name: organizations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.organizations_id_seq', 2, true);


--
-- Name: package_loans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.package_loans_id_seq', 7, true);


--
-- Name: records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.records_id_seq', 7, true);


--
-- Name: report_actions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.report_actions_id_seq', 4, true);


--
-- Name: report_deliveries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.report_deliveries_id_seq', 1, false);


--
-- Name: requested_tests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.requested_tests_id_seq', 1, false);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reviews_id_seq', 1, true);


--
-- Name: sample_catalog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sample_catalog_id_seq', 176, true);


--
-- Name: sample_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sample_events_id_seq', 1, false);


--
-- Name: sample_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sample_groups_id_seq', 8, true);


--
-- Name: template_field_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.template_field_mappings_id_seq', 1093, true);


--
-- Name: attachments attachments_attachment_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT attachments_attachment_id_key UNIQUE (attachment_id);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: commissions commissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commissions
    ADD CONSTRAINT commissions_pkey PRIMARY KEY (commission_no);


--
-- Name: device_presets device_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.device_presets
    ADD CONSTRAINT device_presets_pkey PRIMARY KEY (experiment);


--
-- Name: document_versions document_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_versions
    ADD CONSTRAINT document_versions_pkey PRIMARY KEY (id);


--
-- Name: equipment_incident_actions equipment_incident_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_incident_actions
    ADD CONSTRAINT equipment_incident_actions_pkey PRIMARY KEY (id);


--
-- Name: equipment_incidents equipment_incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_incidents
    ADD CONSTRAINT equipment_incidents_pkey PRIMARY KEY (incident_no);


--
-- Name: equipment_registry equipment_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_registry
    ADD CONSTRAINT equipment_registry_pkey PRIMARY KEY (management_no);


--
-- Name: experiment_config_columns experiment_config_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_columns
    ADD CONSTRAINT experiment_config_columns_pkey PRIMARY KEY (id);


--
-- Name: experiment_config_equipment experiment_config_equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_equipment
    ADD CONSTRAINT experiment_config_equipment_pkey PRIMARY KEY (config_id, management_no);


--
-- Name: experiment_config_fields experiment_config_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_fields
    ADD CONSTRAINT experiment_config_fields_pkey PRIMARY KEY (id);


--
-- Name: experiment_config_photo_checkpoints experiment_config_photo_checkpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_photo_checkpoints
    ADD CONSTRAINT experiment_config_photo_checkpoints_pkey PRIMARY KEY (id);


--
-- Name: experiment_config_prechecks experiment_config_prechecks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_prechecks
    ADD CONSTRAINT experiment_config_prechecks_pkey PRIMARY KEY (id);


--
-- Name: experiment_config_validation_rules experiment_config_validation_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_validation_rules
    ADD CONSTRAINT experiment_config_validation_rules_pkey PRIMARY KEY (id);


--
-- Name: experiment_config_versions experiment_config_versions_experiment_code_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_versions
    ADD CONSTRAINT experiment_config_versions_experiment_code_version_key UNIQUE (experiment_code, version);


--
-- Name: experiment_config_versions experiment_config_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_versions
    ADD CONSTRAINT experiment_config_versions_pkey PRIMARY KEY (id);


--
-- Name: experiment_equipment_bindings experiment_equipment_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_equipment_bindings
    ADD CONSTRAINT experiment_equipment_bindings_pkey PRIMARY KEY (experiment, management_no);


--
-- Name: experiment_methods experiment_methods_experiment_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_methods
    ADD CONSTRAINT experiment_methods_experiment_name_key UNIQUE (experiment_name);


--
-- Name: experiment_methods experiment_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_methods
    ADD CONSTRAINT experiment_methods_pkey PRIMARY KEY (experiment_code);


--
-- Name: experiment_standards experiment_standards_experiment_code_standard_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_standards
    ADD CONSTRAINT experiment_standards_experiment_code_standard_key UNIQUE (experiment_code, standard);


--
-- Name: experiment_standards experiment_standards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_standards
    ADD CONSTRAINT experiment_standards_pkey PRIMARY KEY (id);


--
-- Name: form_drafts form_drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_drafts
    ADD CONSTRAINT form_drafts_pkey PRIMARY KEY (session_token, page, draft_key);


--
-- Name: hazardous_waste_records hazardous_waste_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hazardous_waste_records
    ADD CONSTRAINT hazardous_waste_records_pkey PRIMARY KEY (disposal_no);


--
-- Name: modification_logs modification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modification_logs
    ADD CONSTRAINT modification_logs_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: objection_actions objection_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objection_actions
    ADD CONSTRAINT objection_actions_pkey PRIMARY KEY (id);


--
-- Name: objections objections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objections
    ADD CONSTRAINT objections_pkey PRIMARY KEY (objection_no);


--
-- Name: organizations organizations_org_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_org_code_key UNIQUE (org_code);


--
-- Name: organizations organizations_org_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_org_name_key UNIQUE (org_name);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: package_loans package_loans_package_no_sample_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_loans
    ADD CONSTRAINT package_loans_package_no_sample_no_key UNIQUE (package_no, sample_no);


--
-- Name: package_loans package_loans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_loans
    ADD CONSTRAINT package_loans_pkey PRIMARY KEY (id);


--
-- Name: records records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_pkey PRIMARY KEY (id);


--
-- Name: records records_record_no_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_record_no_version_key UNIQUE (record_no, version);


--
-- Name: report_actions report_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_actions
    ADD CONSTRAINT report_actions_pkey PRIMARY KEY (id);


--
-- Name: report_deliveries report_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_deliveries
    ADD CONSTRAINT report_deliveries_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (report_no);


--
-- Name: requested_tests requested_tests_group_id_experiment_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requested_tests
    ADD CONSTRAINT requested_tests_group_id_experiment_code_key UNIQUE (group_id, experiment_code);


--
-- Name: requested_tests requested_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requested_tests
    ADD CONSTRAINT requested_tests_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: sample_catalog sample_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_catalog
    ADD CONSTRAINT sample_catalog_pkey PRIMARY KEY (id);


--
-- Name: sample_catalog sample_catalog_sample_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_catalog
    ADD CONSTRAINT sample_catalog_sample_code_key UNIQUE (sample_code);


--
-- Name: sample_events sample_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_events
    ADD CONSTRAINT sample_events_pkey PRIMARY KEY (id);


--
-- Name: sample_groups sample_groups_group_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_groups
    ADD CONSTRAINT sample_groups_group_no_key UNIQUE (group_no);


--
-- Name: sample_groups sample_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_groups
    ADD CONSTRAINT sample_groups_pkey PRIMARY KEY (id);


--
-- Name: samples samples_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.samples
    ADD CONSTRAINT samples_pkey PRIMARY KEY (sample_no);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (token);


--
-- Name: signatures signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signatures
    ADD CONSTRAINT signatures_pkey PRIMARY KEY (username);


--
-- Name: task_config_snapshots task_config_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_config_snapshots
    ADD CONSTRAINT task_config_snapshots_pkey PRIMARY KEY (task_no);


--
-- Name: task_packages task_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_packages
    ADD CONSTRAINT task_packages_pkey PRIMARY KEY (package_no);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (task_no);


--
-- Name: template_field_mappings template_field_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_field_mappings
    ADD CONSTRAINT template_field_mappings_pkey PRIMARY KEY (id);


--
-- Name: template_versions template_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_versions
    ADD CONSTRAINT template_versions_pkey PRIMARY KEY (experiment, doc_type, version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: idx_attachments_task; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attachments_task ON public.attachments USING btree (task_no);


--
-- Name: idx_audit_logs_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
-- Name: idx_commissions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commissions_status ON public.commissions USING btree (status);


--
-- Name: idx_equipment_incidents_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_equipment_incidents_status ON public.equipment_incidents USING btree (status);


--
-- Name: idx_experiment_config_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_experiment_config_status ON public.experiment_config_versions USING btree (status);


--
-- Name: idx_notifications_recipient; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_recipient ON public.notifications USING btree (recipient, read_at);


--
-- Name: idx_objections_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_objections_report ON public.objections USING btree (report_no);


--
-- Name: idx_package_loans_package; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_package_loans_package ON public.package_loans USING btree (package_no);


--
-- Name: idx_records_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_records_status ON public.records USING btree (status);


--
-- Name: idx_records_task; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_records_task ON public.records USING btree (task_no);


--
-- Name: idx_reports_commission; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reports_commission ON public.reports USING btree (commission_no);


--
-- Name: idx_reports_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reports_status ON public.reports USING btree (status);


--
-- Name: idx_sample_groups_commission; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sample_groups_commission ON public.sample_groups USING btree (commission_no);


--
-- Name: idx_samples_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_samples_group ON public.samples USING btree (group_id);


--
-- Name: idx_sessions_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_username ON public.sessions USING btree (username);


--
-- Name: idx_task_packages_assignee; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_packages_assignee ON public.task_packages USING btree (assignee);


--
-- Name: idx_task_packages_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_packages_status ON public.task_packages USING btree (status);


--
-- Name: idx_tasks_assignee; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_assignee ON public.tasks USING btree (assignee);


--
-- Name: idx_tasks_package; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_package ON public.tasks USING btree (package_no);


--
-- Name: experiment_config_columns experiment_config_columns_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_columns
    ADD CONSTRAINT experiment_config_columns_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.experiment_config_versions(id) ON DELETE CASCADE;


--
-- Name: experiment_config_equipment experiment_config_equipment_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_equipment
    ADD CONSTRAINT experiment_config_equipment_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.experiment_config_versions(id) ON DELETE CASCADE;


--
-- Name: experiment_config_fields experiment_config_fields_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_fields
    ADD CONSTRAINT experiment_config_fields_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.experiment_config_versions(id) ON DELETE CASCADE;


--
-- Name: experiment_config_photo_checkpoints experiment_config_photo_checkpoints_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_photo_checkpoints
    ADD CONSTRAINT experiment_config_photo_checkpoints_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.experiment_config_versions(id) ON DELETE CASCADE;


--
-- Name: experiment_config_prechecks experiment_config_prechecks_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_prechecks
    ADD CONSTRAINT experiment_config_prechecks_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.experiment_config_versions(id) ON DELETE CASCADE;


--
-- Name: experiment_config_validation_rules experiment_config_validation_rules_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_config_validation_rules
    ADD CONSTRAINT experiment_config_validation_rules_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.experiment_config_versions(id) ON DELETE CASCADE;


--
-- Name: experiment_equipment_bindings experiment_equipment_bindings_management_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_equipment_bindings
    ADD CONSTRAINT experiment_equipment_bindings_management_no_fkey FOREIGN KEY (management_no) REFERENCES public.equipment_registry(management_no);


--
-- Name: experiment_standards experiment_standards_experiment_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_standards
    ADD CONSTRAINT experiment_standards_experiment_code_fkey FOREIGN KEY (experiment_code) REFERENCES public.experiment_methods(experiment_code) ON DELETE CASCADE;


--
-- Name: report_actions report_actions_report_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_actions
    ADD CONSTRAINT report_actions_report_no_fkey FOREIGN KEY (report_no) REFERENCES public.reports(report_no);


--
-- Name: requested_tests requested_tests_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requested_tests
    ADD CONSTRAINT requested_tests_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.sample_groups(id);


--
-- Name: sample_groups sample_groups_commission_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_groups
    ADD CONSTRAINT sample_groups_commission_no_fkey FOREIGN KEY (commission_no) REFERENCES public.commissions(commission_no);


--
-- Name: samples samples_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.samples
    ADD CONSTRAINT samples_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.sample_groups(id);


--
-- Name: sessions sessions_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_username_fkey FOREIGN KEY (username) REFERENCES public.users(username);


--
-- Name: tasks tasks_package_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_package_no_fkey FOREIGN KEY (package_no) REFERENCES public.task_packages(package_no);


--
-- Name: template_field_mappings template_field_mappings_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_field_mappings
    ADD CONSTRAINT template_field_mappings_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.experiment_config_versions(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict sPxvpUFfT8lgrConPFxYg9Ne9DrjMj22xFezYhlVM4v7Hp0b8L6Dx9Sj5Qxoyfj

