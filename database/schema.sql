-- Generated from Supabase pg_dump
-- Apply order: schema.sql -> functions.sql -> data.sql -> indexes.sql -> constraints.sql

--
-- PostgreSQL database dump
--

\restrict 5G7GNXracf6d8n9Twva9IYLtK1zOF4gVUR6IxlhPr5LlmK0e56Wyhfchz45aWAS

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET escape_string_warning = off;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: app_role; Type: TYPE; Schema: public; Owner: -
--

-- Name: auto_assign_wallet(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: calc_ticket_booking_fields(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: calc_ticket_refund_fields(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: calc_visa_application_fields(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: calculate_booking_profit(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: check_package_expiry(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: deactivate_expired_packages(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: gen_refund_invoice_no(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: gen_settlement_no(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: gen_ticket_invoice_no(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: gen_visa_invoice_no(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: generate_installment_schedule(uuid, numeric, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: has_role(uuid, public.app_role); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: notify_booking_completed(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: notify_booking_created(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: notify_booking_status_updated(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: notify_commission_payment(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: notify_payment_completed(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: notify_supplier_payment(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_commission_payment_changed(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_expense_changed(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_moallem_payment_income(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_moallem_payment_wallet(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_payment_completed(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_refund_processed(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_settlement_changed(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_settlement_item_changed(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_supplier_contract_payment(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_supplier_payment_changed(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: on_ticket_refund_changed(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: protect_admin_role(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: protect_admin_role_update(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: recalc_source_received(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: recalculate_wallet_balances(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_booking_commission_paid(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_booking_moallem_paid(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_booking_paid_amount(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_booking_supplier_paid(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_moallem_on_booking(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_moallem_on_deposit(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_wallet_on_cashbook_delete(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_wallet_on_cashbook_insert(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_wallet_on_cashbook_update(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_wallet_on_expense_delete(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_wallet_on_expense_insert(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_wallet_on_moallem_payment_insert(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_wallet_on_payment_delete(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_wallet_on_payment_insert(); Type: FUNCTION; Schema: public; Owner: -
--

-- Name: update_wallet_on_supplier_payment_insert(); Type: FUNCTION; Schema: public; Owner: -
--

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

-- Name: admin_2fa; Type: TABLE; Schema: public; Owner: -
--

-- Name: admin_2fa_codes; Type: TABLE; Schema: public; Owner: -
--

-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

-- Name: blog_posts; Type: TABLE; Schema: public; Owner: -
--

-- Name: booking_documents; Type: TABLE; Schema: public; Owner: -
--

-- Name: booking_members; Type: TABLE; Schema: public; Owner: -
--

-- Name: bookings; Type: TABLE; Schema: public; Owner: -
--

-- Name: cancellation_policies; Type: TABLE; Schema: public; Owner: -
--

-- Name: cms_versions; Type: TABLE; Schema: public; Owner: -
--

-- Name: company_settings; Type: TABLE; Schema: public; Owner: -
--

-- Name: daily_cashbook; Type: TABLE; Schema: public; Owner: -
--

-- Name: expenses; Type: TABLE; Schema: public; Owner: -
--

-- Name: financial_summary; Type: TABLE; Schema: public; Owner: -
--

-- Name: hotel_bookings; Type: TABLE; Schema: public; Owner: -
--

-- Name: hotel_rooms; Type: TABLE; Schema: public; Owner: -
--

-- Name: hotels; Type: TABLE; Schema: public; Owner: -
--

-- Name: installment_plans; Type: TABLE; Schema: public; Owner: -
--

-- Name: moallem_commission_payments; Type: TABLE; Schema: public; Owner: -
--

-- Name: moallem_items; Type: TABLE; Schema: public; Owner: -
--

-- Name: moallem_payments; Type: TABLE; Schema: public; Owner: -
--

-- Name: moallems; Type: TABLE; Schema: public; Owner: -
--

-- Name: notification_logs; Type: TABLE; Schema: public; Owner: -
--

-- Name: notification_settings; Type: TABLE; Schema: public; Owner: -
--

-- Name: online_payment_sessions; Type: TABLE; Schema: public; Owner: -
--

-- Name: otp_codes; Type: TABLE; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_codes FORCE ROW LEVEL SECURITY;


--
-- Name: packages; Type: TABLE; Schema: public; Owner: -
--

-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

-- Name: refund_invoice_seq; Type: SEQUENCE; Schema: public; Owner: -
--

-- Name: refunds; Type: TABLE; Schema: public; Owner: -
--

-- Name: settlement_items; Type: TABLE; Schema: public; Owner: -
--

-- Name: settlement_no_seq; Type: SEQUENCE; Schema: public; Owner: -
--

-- Name: settlements; Type: TABLE; Schema: public; Owner: -
--

-- Name: site_content; Type: TABLE; Schema: public; Owner: -
--

-- Name: supplier_agent_items; Type: TABLE; Schema: public; Owner: -
--

-- Name: supplier_agent_payments; Type: TABLE; Schema: public; Owner: -
--

-- Name: supplier_agents; Type: TABLE; Schema: public; Owner: -
--

-- Name: supplier_contract_payments; Type: TABLE; Schema: public; Owner: -
--

-- Name: supplier_contracts; Type: TABLE; Schema: public; Owner: -
--

-- Name: ticket_bookings; Type: TABLE; Schema: public; Owner: -
--

-- Name: ticket_invoice_seq; Type: SEQUENCE; Schema: public; Owner: -
--

-- Name: ticket_refunds; Type: TABLE; Schema: public; Owner: -
--

-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

-- Name: v_booking_profit; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_booking_profit WITH (security_invoker='on') AS
 SELECT b.id AS booking_id,
    b.tracking_id,
    b.guest_name,
    b.status,
    b.num_travelers,
    b.selling_price_per_person,
    b.cost_price_per_person,
    b.total_amount,
    b.total_cost,
    b.extra_expense,
    b.profit_amount,
    b.paid_amount,
    b.due_amount,
    b.paid_to_supplier,
    b.supplier_due,
    b.paid_by_moallem,
    b.moallem_due,
    b.moallem_id,
    b.commission_per_person,
    b.total_commission,
    b.commission_paid,
    b.commission_due,
    p.name AS package_name,
    p.type AS package_type,
    b.package_id,
    COALESCE(( SELECT sum(pay.amount) AS sum
           FROM public.payments pay
          WHERE ((pay.booking_id = b.id) AND (pay.status = 'completed'::text))), (0)::numeric) AS total_payments,
    COALESCE(( SELECT sum(e.amount) AS sum
           FROM public.expenses e
          WHERE (e.booking_id = b.id)), (0)::numeric) AS total_expenses
   FROM (public.bookings b
     LEFT JOIN public.packages p ON ((b.package_id = p.id)));


--
-- Name: v_customer_profit; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_customer_profit WITH (security_invoker='on') AS
 SELECT pr.id AS customer_id,
    pr.full_name,
    pr.phone,
    count(b.id) AS total_bookings,
    COALESCE(sum(b.total_amount), (0)::numeric) AS total_payments,
    (COALESCE(sum(b.total_cost), (0)::numeric) + COALESCE(sum(b.extra_expense), (0)::numeric)) AS total_expenses,
    COALESCE(sum(b.profit_amount), (0)::numeric) AS profit
   FROM (public.profiles pr
     LEFT JOIN public.bookings b ON ((b.user_id = pr.user_id)))
  GROUP BY pr.id, pr.full_name, pr.phone;


--
-- Name: v_package_profit; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_package_profit WITH (security_invoker='on') AS
 SELECT p.id AS package_id,
    p.name AS package_name,
    p.type AS package_type,
    p.price AS package_price,
    count(b.id) AS total_bookings,
    COALESCE(sum(b.total_amount), (0)::numeric) AS total_revenue,
    COALESCE(sum(b.profit_amount), (0)::numeric) AS profit,
    COALESCE(sum(b.total_cost), (0)::numeric) AS total_expenses
   FROM (public.packages p
     LEFT JOIN public.bookings b ON ((b.package_id = p.id)))
  GROUP BY p.id, p.name, p.type, p.price;


--
-- Name: visa_applications; Type: TABLE; Schema: public; Owner: -
--

-- Name: visa_invoice_seq; Type: SEQUENCE; Schema: public; Owner: -
--

-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: admin_2fa_codes admin_2fa_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: admin_2fa admin_2fa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: blog_posts blog_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: blog_posts blog_posts_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_posts
    ADD CONSTRAINT blog_posts_slug_key UNIQUE (slug);


--
-- Name: booking_documents booking_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: booking_members booking_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: bookings bookings_tracking_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_tracking_id_key UNIQUE (tracking_id);


--
-- Name: cancellation_policies cancellation_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: cms_versions cms_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: company_settings company_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: company_settings company_settings_setting_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_settings
    ADD CONSTRAINT company_settings_setting_key_key UNIQUE (setting_key);


--
-- Name: daily_cashbook daily_cashbook_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: financial_summary financial_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: hotel_bookings hotel_bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: hotel_rooms hotel_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: hotels hotels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: installment_plans installment_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallem_commission_payments moallem_commission_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallem_items moallem_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallem_payments moallem_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallems moallems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: notification_logs notification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: notification_settings notification_settings_event_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_settings
    ADD CONSTRAINT notification_settings_event_key_key UNIQUE (event_key);


--
-- Name: notification_settings notification_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: online_payment_sessions online_payment_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: online_payment_sessions online_payment_sessions_tran_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_payment_sessions
    ADD CONSTRAINT online_payment_sessions_tran_id_key UNIQUE (tran_id);


--
-- Name: otp_codes otp_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: packages packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: profiles profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_user_id_key UNIQUE (user_id);


--
-- Name: refunds refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: settlement_items settlement_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: settlements settlements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: settlements settlements_settlement_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_settlement_no_key UNIQUE (settlement_no);


--
-- Name: site_content site_content_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: site_content site_content_section_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_content
    ADD CONSTRAINT site_content_section_key_key UNIQUE (section_key);


--
-- Name: supplier_agent_items supplier_agent_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_agent_payments supplier_agent_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_agents supplier_agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_contract_payments supplier_contract_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_contracts supplier_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: ticket_bookings ticket_bookings_invoice_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_bookings
    ADD CONSTRAINT ticket_bookings_invoice_no_key UNIQUE (invoice_no);


--
-- Name: ticket_bookings ticket_bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: ticket_refunds ticket_refunds_invoice_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_refunds
    ADD CONSTRAINT ticket_refunds_invoice_no_key UNIQUE (invoice_no);


--
-- Name: ticket_refunds ticket_refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: user_roles user_roles_user_id_role_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_key UNIQUE (user_id, role);


--
-- Name: visa_applications visa_applications_invoice_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visa_applications
    ADD CONSTRAINT visa_applications_invoice_no_key UNIQUE (invoice_no);


--
-- Name: visa_applications visa_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

-- Name: idx_admin_2fa_codes_user; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_audit_logs_actor; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_audit_logs_entity; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_blog_posts_slug; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_blog_posts_status; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_cms_versions_section; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_expenses_category; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_expenses_date; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_notification_logs_booking; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_notification_logs_created; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_notification_logs_event; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_notification_logs_user; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_ops_booking; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_ops_status; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_otp_codes_phone_expires; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_packages_show_on_website; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_packages_status; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_profiles_status; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_settlement_items_settlement; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_settlement_items_source; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_settlements_date; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_settlements_no; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_ticket_bookings_collection; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_ticket_bookings_invoice; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_ticket_bookings_status; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_ticket_bookings_vendor; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_ticket_refunds_booking; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_ticket_refunds_invoice; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_transactions_booking_id; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_transactions_date; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_transactions_source_id; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_transactions_source_type; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_transactions_type; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_visa_applications_invoice; Type: INDEX; Schema: public; Owner: -
--

-- Name: idx_visa_applications_status; Type: INDEX; Schema: public; Owner: -
--

-- Name: moallem_commission_payments trg_auto_wallet_commission_payments; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: supplier_contract_payments trg_auto_wallet_contract_payments; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: moallem_payments trg_auto_wallet_moallem_payments; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: payments trg_auto_wallet_payments; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: supplier_agent_payments trg_auto_wallet_supplier_payments; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: ticket_bookings trg_calc_ticket_booking; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: ticket_refunds trg_calc_ticket_refund; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: visa_applications trg_calc_visa_application; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: bookings trg_calculate_booking_profit; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: daily_cashbook trg_cashbook_delete_wallet; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: daily_cashbook trg_cashbook_insert_wallet; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: daily_cashbook trg_cashbook_update_wallet; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: packages trg_check_package_expiry; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: bookings trg_notify_booking_completed; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: bookings trg_notify_booking_created; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: bookings trg_notify_booking_status; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: bookings trg_notify_booking_status_updated; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: moallem_commission_payments trg_notify_commission_payment; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: payments trg_notify_payment_completed; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: supplier_agent_payments trg_notify_supplier_payment; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: moallem_commission_payments trg_on_commission_payment_changed; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: expenses trg_on_expense_changed; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: moallem_payments trg_on_moallem_payment_income; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: moallem_payments trg_on_moallem_payment_wallet; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: payments trg_on_payment_completed; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: refunds trg_on_refund_processed; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: settlements trg_on_settlement_changed; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: supplier_agent_payments trg_on_supplier_payment_changed; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: ticket_refunds trg_on_ticket_refund_changed; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: user_roles trg_protect_admin_role; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: user_roles trg_protect_admin_role_update; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: settlement_items trg_settlement_item_changed; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: supplier_contract_payments trg_supplier_contract_payment; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: moallem_commission_payments trg_update_booking_commission_paid; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: moallem_payments trg_update_booking_moallem_paid; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: payments trg_update_booking_paid_amount; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: supplier_agent_payments trg_update_booking_supplier_paid; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: bookings trg_update_bookings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: hotels trg_update_hotels_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: bookings trg_update_moallem_on_booking; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: moallem_payments trg_update_moallem_on_deposit; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: moallems trg_update_moallems_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: supplier_agents trg_update_supplier_agents_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

-- Name: booking_documents booking_documents_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: booking_documents booking_documents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: booking_members booking_members_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: booking_members booking_members_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: bookings bookings_installment_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: bookings bookings_moallem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: bookings bookings_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: bookings bookings_supplier_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: company_settings company_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: daily_cashbook daily_cashbook_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: expenses expenses_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: expenses expenses_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: expenses expenses_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: hotel_bookings hotel_bookings_hotel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: hotel_bookings hotel_bookings_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: hotel_bookings hotel_bookings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: hotel_rooms hotel_rooms_hotel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallem_commission_payments moallem_commission_payments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallem_commission_payments moallem_commission_payments_moallem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallem_commission_payments moallem_commission_payments_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallem_items moallem_items_moallem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallem_payments moallem_payments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallem_payments moallem_payments_moallem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: moallem_payments moallem_payments_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: notification_logs notification_logs_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: notification_logs notification_logs_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: notification_settings notification_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: online_payment_sessions online_payment_sessions_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: online_payment_sessions online_payment_sessions_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: payments payments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: payments payments_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: refunds refunds_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: refunds refunds_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: refunds refunds_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: settlement_items settlement_items_settlement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: settlements settlements_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_agent_items supplier_agent_items_supplier_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_agent_payments supplier_agent_payments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_agent_payments supplier_agent_payments_supplier_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_agent_payments supplier_agent_payments_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_contract_payments supplier_contract_payments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_contract_payments supplier_contract_payments_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_contract_payments supplier_contract_payments_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: supplier_contracts supplier_contracts_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: ticket_bookings ticket_bookings_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: ticket_refunds ticket_refunds_ticket_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: ticket_refunds ticket_refunds_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: ticket_refunds ticket_refunds_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: transactions transactions_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: visa_applications visa_applications_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

-- Name: profiles Admins can delete profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete profiles" ON public.profiles FOR DELETE USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: user_roles Admins can delete user roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete user roles" ON public.user_roles FOR DELETE USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: audit_logs Admins can insert audit logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert audit logs" ON public.audit_logs FOR INSERT WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: profiles Admins can insert profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert profiles" ON public.profiles FOR INSERT WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: user_roles Admins can insert user roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert user roles" ON public.user_roles FOR INSERT WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: accounts Admins can manage accounts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage accounts" ON public.accounts USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: bookings Admins can manage all bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage all bookings" ON public.bookings USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: booking_documents Admins can manage all documents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage all documents" ON public.booking_documents USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: blog_posts Admins can manage blog posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage blog posts" ON public.blog_posts USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: booking_members Admins can manage booking members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage booking members" ON public.booking_members USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: cancellation_policies Admins can manage cancellation policies; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage cancellation policies" ON public.cancellation_policies USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: cms_versions Admins can manage cms versions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage cms versions" ON public.cms_versions USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: moallem_commission_payments Admins can manage commission payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage commission payments" ON public.moallem_commission_payments USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: company_settings Admins can manage company settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage company settings" ON public.company_settings USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: daily_cashbook Admins can manage daily cashbook; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage daily cashbook" ON public.daily_cashbook TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: expenses Admins can manage expenses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage expenses" ON public.expenses USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: financial_summary Admins can manage financial summary; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage financial summary" ON public.financial_summary USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hotel_bookings Admins can manage hotel bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage hotel bookings" ON public.hotel_bookings USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hotels Admins can manage hotels; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage hotels" ON public.hotels USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: moallem_items Admins can manage moallem items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage moallem items" ON public.moallem_items TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: moallem_payments Admins can manage moallem payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage moallem payments" ON public.moallem_payments USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: moallems Admins can manage moallems; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage moallems" ON public.moallems USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: notification_logs Admins can manage notification logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage notification logs" ON public.notification_logs USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: notification_settings Admins can manage notification settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage notification settings" ON public.notification_settings USING ((EXISTS ( SELECT 1
   FROM public.user_roles
  WHERE ((user_roles.user_id = auth.uid()) AND (user_roles.role = 'admin'::public.app_role))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.user_roles
  WHERE ((user_roles.user_id = auth.uid()) AND (user_roles.role = 'admin'::public.app_role)))));


--
-- Name: packages Admins can manage packages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage packages" ON public.packages USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: payments Admins can manage payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage payments" ON public.payments USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: installment_plans Admins can manage plans; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage plans" ON public.installment_plans USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: refunds Admins can manage refunds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage refunds" ON public.refunds USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hotel_rooms Admins can manage rooms; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage rooms" ON public.hotel_rooms USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: site_content Admins can manage site content; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage site content" ON public.site_content USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: supplier_agent_items Admins can manage supplier agent items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage supplier agent items" ON public.supplier_agent_items USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: supplier_agent_payments Admins can manage supplier agent payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage supplier agent payments" ON public.supplier_agent_payments USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: supplier_agents Admins can manage supplier agents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage supplier agents" ON public.supplier_agents USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: supplier_contract_payments Admins can manage supplier contract payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage supplier contract payments" ON public.supplier_contract_payments USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: supplier_contracts Admins can manage supplier contracts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage supplier contracts" ON public.supplier_contracts USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: transactions Admins can manage transactions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage transactions" ON public.transactions USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: accounts Admins can read accounts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can read accounts" ON public.accounts FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: financial_summary Admins can read financial summary; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can read financial summary" ON public.financial_summary FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: profiles Admins can update all profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update all profiles" ON public.profiles FOR UPDATE USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: user_roles Admins can update user roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update user roles" ON public.user_roles FOR UPDATE USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: profiles Admins can view all profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can view all profiles" ON public.profiles FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: user_roles Admins can view all user roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can view all user roles" ON public.user_roles FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: audit_logs Admins can view audit logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can view audit logs" ON public.audit_logs FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: online_payment_sessions Admins manage online payment sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage online payment sessions" ON public.online_payment_sessions TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: settlement_items Admins manage settlement items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage settlement items" ON public.settlement_items USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: settlements Admins manage settlements; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage settlements" ON public.settlements USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: admin_2fa Admins manage their own 2FA settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage their own 2FA settings" ON public.admin_2fa USING ((public.has_role(auth.uid(), 'admin'::public.app_role) AND (auth.uid() = user_id))) WITH CHECK ((public.has_role(auth.uid(), 'admin'::public.app_role) AND (auth.uid() = user_id)));


--
-- Name: ticket_bookings Admins manage ticket bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage ticket bookings" ON public.ticket_bookings USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: ticket_refunds Admins manage ticket refunds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage ticket refunds" ON public.ticket_refunds USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: visa_applications Admins manage visa applications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage visa applications" ON public.visa_applications USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hotels Anyone can view active hotels; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view active hotels" ON public.hotels FOR SELECT USING ((is_active = true));


--
-- Name: packages Anyone can view active packages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view active packages" ON public.packages FOR SELECT USING ((is_active = true));


--
-- Name: installment_plans Anyone can view active plans; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view active plans" ON public.installment_plans FOR SELECT USING ((is_active = true));


--
-- Name: cancellation_policies Anyone can view active policies; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view active policies" ON public.cancellation_policies FOR SELECT USING ((is_active = true));


--
-- Name: hotel_rooms Anyone can view available rooms; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view available rooms" ON public.hotel_rooms FOR SELECT USING ((is_available = true));


--
-- Name: blog_posts Anyone can view published posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view published posts" ON public.blog_posts FOR SELECT USING ((status = 'published'::text));


--
-- Name: site_content Anyone can view site content; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view site content" ON public.site_content FOR SELECT USING (true);


--
-- Name: company_settings Authenticated users can view company settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can view company settings" ON public.company_settings FOR SELECT USING ((auth.uid() IS NOT NULL));


--
-- Name: notification_settings Authenticated users can view notification settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can view notification settings" ON public.notification_settings FOR SELECT USING ((auth.uid() IS NOT NULL));


--
-- Name: moallem_commission_payments Staff can view commission payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view commission payments" ON public.moallem_commission_payments FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: daily_cashbook Staff can view daily cashbook; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view daily cashbook" ON public.daily_cashbook FOR SELECT TO authenticated USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: moallem_items Staff can view moallem items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view moallem items" ON public.moallem_items FOR SELECT TO authenticated USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: moallem_payments Staff can view moallem payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view moallem payments" ON public.moallem_payments FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: moallems Staff can view moallems; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view moallems" ON public.moallems FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: refunds Staff can view refunds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view refunds" ON public.refunds FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: supplier_agent_items Staff can view supplier agent items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view supplier agent items" ON public.supplier_agent_items FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: supplier_agent_payments Staff can view supplier agent payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view supplier agent payments" ON public.supplier_agent_payments FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: supplier_agents Staff can view supplier agents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view supplier agents" ON public.supplier_agents FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: supplier_contract_payments Staff can view supplier contract payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view supplier contract payments" ON public.supplier_contract_payments FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: supplier_contracts Staff can view supplier contracts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view supplier contracts" ON public.supplier_contracts FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: settlement_items Staff view settlement items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff view settlement items" ON public.settlement_items FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: settlements Staff view settlements; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff view settlements" ON public.settlements FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: ticket_bookings Staff view ticket bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff view ticket bookings" ON public.ticket_bookings FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: ticket_refunds Staff view ticket refunds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff view ticket refunds" ON public.ticket_refunds FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: visa_applications Staff view visa applications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff view visa applications" ON public.visa_applications FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: bookings Users can create bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create bookings" ON public.bookings FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));


--
-- Name: hotel_bookings Users can create hotel bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create hotel bookings" ON public.hotel_bookings FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: booking_documents Users can delete own documents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete own documents" ON public.booking_documents FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: profiles Users can insert own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: profiles Users can update own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: booking_documents Users can upload own documents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can upload own documents" ON public.booking_documents FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: booking_members Users can view own booking members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own booking members" ON public.booking_members FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.bookings
  WHERE ((bookings.id = booking_members.booking_id) AND (bookings.user_id = auth.uid())))));


--
-- Name: bookings Users can view own bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own bookings" ON public.bookings FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: booking_documents Users can view own documents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own documents" ON public.booking_documents FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: hotel_bookings Users can view own hotel bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own hotel bookings" ON public.hotel_bookings FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: notification_logs Users can view own notification logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own notification logs" ON public.notification_logs FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: payments Users can view own payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: profiles Users can view own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_roles Users can view own roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own roles" ON public.user_roles FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: transactions Users can view own transactions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own transactions" ON public.transactions FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: online_payment_sessions Users view own payment sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users view own payment sessions" ON public.online_payment_sessions FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: accounts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

--
-- Name: admin_2fa; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_2fa ENABLE ROW LEVEL SECURITY;

--
-- Name: admin_2fa_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_2fa_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: blog_posts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;

--
-- Name: booking_documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.booking_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: booking_members; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.booking_members ENABLE ROW LEVEL SECURITY;

--
-- Name: bookings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

--
-- Name: cancellation_policies; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cancellation_policies ENABLE ROW LEVEL SECURITY;

--
-- Name: cms_versions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cms_versions ENABLE ROW LEVEL SECURITY;

--
-- Name: company_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: daily_cashbook; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.daily_cashbook ENABLE ROW LEVEL SECURITY;

--
-- Name: expenses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

--
-- Name: financial_summary; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.financial_summary ENABLE ROW LEVEL SECURITY;

--
-- Name: hotel_bookings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hotel_bookings ENABLE ROW LEVEL SECURITY;

--
-- Name: hotel_rooms; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hotel_rooms ENABLE ROW LEVEL SECURITY;

--
-- Name: hotels; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hotels ENABLE ROW LEVEL SECURITY;

--
-- Name: installment_plans; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.installment_plans ENABLE ROW LEVEL SECURITY;

--
-- Name: moallem_commission_payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moallem_commission_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: moallem_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moallem_items ENABLE ROW LEVEL SECURITY;

--
-- Name: moallem_payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moallem_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: moallems; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moallems ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: online_payment_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.online_payment_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: otp_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: packages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;

--
-- Name: payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: refunds; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;

--
-- Name: settlement_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.settlement_items ENABLE ROW LEVEL SECURITY;

--
-- Name: settlements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;

--
-- Name: site_content; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_content ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_agent_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_agent_items ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_agent_payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_agent_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_agents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_agents ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_contract_payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_contract_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_contracts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_contracts ENABLE ROW LEVEL SECURITY;

--
-- Name: ticket_bookings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ticket_bookings ENABLE ROW LEVEL SECURITY;

--
-- Name: ticket_refunds; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ticket_refunds ENABLE ROW LEVEL SECURITY;

--
-- Name: transactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: user_roles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

--
-- Name: visa_applications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.visa_applications ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict 5G7GNXracf6d8n9Twva9IYLtK1zOF4gVUR6IxlhPr5LlmK0e56Wyhfchz45aWAS

CREATE SCHEMA public;


--
CREATE TYPE public.app_role AS ENUM (
    'admin',
    'user',
    'manager',
    'staff',
    'viewer',
    'accountant',
    'booking',
    'cms'
);


--
CREATE TABLE public.accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    balance numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT accounts_balance_non_negative CHECK ((balance >= (0)::numeric)),
    CONSTRAINT accounts_type_check CHECK ((type = ANY (ARRAY['income'::text, 'expense'::text, 'asset'::text, 'liability'::text])))
);


--
CREATE TABLE public.admin_2fa (
    user_id uuid NOT NULL,
    sms_enabled boolean DEFAULT false NOT NULL,
    sms_phone text,
    totp_enabled boolean DEFAULT false NOT NULL,
    totp_secret text,
    totp_secret_pending text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.admin_2fa_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    code text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    actor_id uuid,
    actor_email text,
    actor_role text,
    action text NOT NULL,
    entity_type text,
    entity_id text,
    method text,
    path text,
    status_code integer,
    ip_address text,
    user_agent text,
    changes jsonb DEFAULT '{}'::jsonb,
    metadata jsonb DEFAULT '{}'::jsonb
);


--
CREATE TABLE public.blog_posts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    slug text NOT NULL,
    content text DEFAULT ''::text NOT NULL,
    excerpt text,
    image_url text,
    status text DEFAULT 'draft'::text NOT NULL,
    author_id uuid,
    tags text[] DEFAULT '{}'::text[],
    published_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.booking_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_id uuid NOT NULL,
    user_id uuid NOT NULL,
    document_type text NOT NULL,
    file_name text NOT NULL,
    file_path text NOT NULL,
    file_size integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT booking_documents_document_type_check CHECK ((document_type = ANY (ARRAY['passport'::text, 'nid'::text, 'photo'::text, 'other'::text])))
);


--
CREATE TABLE public.booking_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_id uuid NOT NULL,
    full_name text NOT NULL,
    passport_number text,
    package_id uuid,
    selling_price numeric DEFAULT 0 NOT NULL,
    discount numeric DEFAULT 0 NOT NULL,
    final_price numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.bookings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tracking_id text DEFAULT ('MTH-'::text || upper(substr((gen_random_uuid())::text, 1, 8))) NOT NULL,
    user_id uuid,
    package_id uuid NOT NULL,
    installment_plan_id uuid,
    total_amount numeric(12,2) NOT NULL,
    paid_amount numeric(12,2) DEFAULT 0 NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    num_travelers integer DEFAULT 1 NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    guest_name text,
    guest_phone text,
    guest_email text,
    guest_address text,
    guest_passport text,
    due_amount numeric DEFAULT 0,
    moallem_id uuid,
    supplier_agent_id uuid,
    cost_price_per_person numeric DEFAULT 0,
    total_cost numeric DEFAULT 0,
    selling_price_per_person numeric DEFAULT 0,
    extra_expense numeric DEFAULT 0,
    profit_amount numeric DEFAULT 0,
    paid_to_supplier numeric DEFAULT 0 NOT NULL,
    supplier_due numeric DEFAULT 0 NOT NULL,
    paid_by_moallem numeric DEFAULT 0 NOT NULL,
    moallem_due numeric DEFAULT 0 NOT NULL,
    commission_per_person numeric DEFAULT 0 NOT NULL,
    total_commission numeric DEFAULT 0 NOT NULL,
    commission_paid numeric DEFAULT 0 NOT NULL,
    commission_due numeric DEFAULT 0 NOT NULL,
    booking_type text DEFAULT 'individual'::text NOT NULL,
    discount numeric DEFAULT 0 NOT NULL,
    CONSTRAINT bookings_paid_amount_non_negative CHECK ((paid_amount >= (0)::numeric)),
    CONSTRAINT bookings_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text])))
);


--
CREATE TABLE public.cancellation_policies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    refund_type text DEFAULT 'percentage'::text NOT NULL,
    refund_value numeric DEFAULT 0 NOT NULL,
    min_days_before_departure integer DEFAULT 0,
    is_default boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT cancellation_policies_refund_type_check CHECK ((refund_type = ANY (ARRAY['percentage'::text, 'flat'::text])))
);


--
CREATE TABLE public.cms_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    section_key text NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    note text
);


--
CREATE TABLE public.company_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    setting_key text NOT NULL,
    setting_value jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid
);


--
CREATE TABLE public.daily_cashbook (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    date date DEFAULT CURRENT_DATE NOT NULL,
    type text NOT NULL,
    description text NOT NULL,
    amount numeric NOT NULL,
    category text DEFAULT 'other'::text NOT NULL,
    wallet_account_id uuid,
    payment_method text DEFAULT 'cash'::text,
    notes text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT daily_cashbook_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT daily_cashbook_type_check CHECK ((type = ANY (ARRAY['income'::text, 'expense'::text])))
);


--
CREATE TABLE public.expenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    amount numeric NOT NULL,
    category text NOT NULL,
    booking_id uuid,
    date date DEFAULT CURRENT_DATE NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    customer_id uuid,
    package_id uuid,
    expense_type text DEFAULT 'other'::text NOT NULL,
    wallet_account_id uuid,
    CONSTRAINT expenses_amount_positive CHECK ((amount > (0)::numeric))
);


--
CREATE TABLE public.financial_summary (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    total_income numeric DEFAULT 0 NOT NULL,
    total_expense numeric DEFAULT 0 NOT NULL,
    net_profit numeric DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.hotel_bookings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    hotel_id uuid NOT NULL,
    room_id uuid NOT NULL,
    check_in date NOT NULL,
    check_out date NOT NULL,
    guests integer DEFAULT 1 NOT NULL,
    total_price numeric(10,2) NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT hotel_bookings_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'cancelled'::text, 'completed'::text])))
);


--
CREATE TABLE public.hotel_rooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    hotel_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    capacity integer DEFAULT 2 NOT NULL,
    price_per_night numeric(10,2) NOT NULL,
    amenities jsonb DEFAULT '[]'::jsonb,
    image_url text,
    is_available boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.hotels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    location text NOT NULL,
    city text DEFAULT 'Makkah'::text NOT NULL,
    description text,
    star_rating integer,
    distance_to_haram text,
    amenities jsonb DEFAULT '[]'::jsonb,
    image_url text,
    gallery jsonb DEFAULT '[]'::jsonb,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT hotels_star_rating_check CHECK (((star_rating >= 1) AND (star_rating <= 5)))
);


--
CREATE TABLE public.installment_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    num_installments integer NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.moallem_commission_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    moallem_id uuid NOT NULL,
    booking_id uuid,
    amount numeric NOT NULL,
    payment_method text DEFAULT 'cash'::text,
    date date DEFAULT CURRENT_DATE NOT NULL,
    notes text,
    wallet_account_id uuid,
    recorded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.moallem_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    moallem_id uuid NOT NULL,
    description text NOT NULL,
    quantity numeric DEFAULT 1 NOT NULL,
    unit_price numeric DEFAULT 0 NOT NULL,
    total_amount numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.moallem_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    moallem_id uuid NOT NULL,
    amount numeric NOT NULL,
    payment_method text DEFAULT 'cash'::text,
    date date DEFAULT CURRENT_DATE NOT NULL,
    notes text,
    wallet_account_id uuid,
    recorded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    booking_id uuid,
    receipt_file_path text
);


--
CREATE TABLE public.moallems (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    phone text,
    address text,
    nid_number text,
    contract_date date,
    notes text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    total_deposit numeric DEFAULT 0 NOT NULL,
    total_due numeric DEFAULT 0 NOT NULL,
    contracted_hajji integer DEFAULT 0 NOT NULL,
    contracted_amount numeric DEFAULT 0 NOT NULL
);


--
CREATE TABLE public.notification_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    booking_id uuid,
    payment_id uuid,
    event_type text NOT NULL,
    channel text NOT NULL,
    recipient text NOT NULL,
    subject text,
    message text NOT NULL,
    status text DEFAULT 'sent'::text NOT NULL,
    error_detail text,
    sent_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.notification_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_key text NOT NULL,
    event_label text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email_enabled boolean DEFAULT true NOT NULL,
    sms_enabled boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid
);


--
CREATE TABLE public.online_payment_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tran_id text NOT NULL,
    booking_id uuid,
    user_id uuid,
    customer_phone text,
    amount numeric NOT NULL,
    currency text DEFAULT 'BDT'::text NOT NULL,
    status text DEFAULT 'initiated'::text NOT NULL,
    gateway text DEFAULT 'sslcommerz'::text NOT NULL,
    gateway_response jsonb,
    payment_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.otp_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phone text NOT NULL,
    code text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.packages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    description text,
    price numeric(12,2) NOT NULL,
    duration_days integer,
    features jsonb DEFAULT '[]'::jsonb,
    image_url text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    start_date date,
    services jsonb DEFAULT '[]'::jsonb,
    expiry_date date,
    status text DEFAULT 'active'::text NOT NULL,
    show_on_website boolean DEFAULT true NOT NULL,
    rating numeric DEFAULT 4.9 NOT NULL,
    highlight_tag text,
    CONSTRAINT packages_type_check CHECK ((type = ANY (ARRAY['hajj'::text, 'umrah'::text, 'visa'::text, 'hotel'::text, 'transport'::text, 'ziyara'::text, 'tour'::text, 'air_ticket'::text, 'emergency'::text, 'other'::text])))
);


--
CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_id uuid NOT NULL,
    user_id uuid NOT NULL,
    amount numeric(12,2) NOT NULL,
    installment_number integer,
    payment_method text DEFAULT 'manual'::text,
    status text DEFAULT 'pending'::text NOT NULL,
    due_date date,
    paid_at timestamp with time zone,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    transaction_id text,
    customer_id uuid,
    wallet_account_id uuid,
    receipt_file_path text,
    CONSTRAINT payments_amount_positive CHECK ((amount > (0)::numeric)),
    CONSTRAINT payments_payment_method_check CHECK ((payment_method = ANY (ARRAY['cash'::text, 'bkash'::text, 'nagad'::text, 'bank'::text, 'manual'::text, 'online'::text, 'bank_transfer'::text]))),
    CONSTRAINT payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'failed'::text, 'refunded'::text])))
);


--
CREATE TABLE public.profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    full_name text,
    phone text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    address text,
    passport_number text,
    email text,
    nid_number text,
    date_of_birth date,
    emergency_contact text,
    notes text,
    status text DEFAULT 'active'::text NOT NULL
);


--
CREATE SEQUENCE public.refund_invoice_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
CREATE TABLE public.refunds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_id uuid NOT NULL,
    policy_id uuid,
    original_amount numeric DEFAULT 0 NOT NULL,
    refund_amount numeric DEFAULT 0 NOT NULL,
    deduction_amount numeric DEFAULT 0 NOT NULL,
    refund_method text DEFAULT 'cash'::text,
    wallet_account_id uuid,
    reason text,
    status text DEFAULT 'pending'::text NOT NULL,
    processed_by uuid,
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT refunds_refund_method_check CHECK ((refund_method = ANY (ARRAY['cash'::text, 'bkash'::text, 'nagad'::text, 'bank'::text, 'bank_transfer'::text]))),
    CONSTRAINT refunds_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'processed'::text, 'rejected'::text])))
);


--
CREATE TABLE public.settlement_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    settlement_id uuid NOT NULL,
    source_type text NOT NULL,
    source_id uuid NOT NULL,
    invoice_no text,
    amount_applied numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE SEQUENCE public.settlement_no_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
CREATE TABLE public.settlements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    settlement_no text DEFAULT public.gen_settlement_no() NOT NULL,
    settlement_date date DEFAULT CURRENT_DATE NOT NULL,
    payer_name text,
    payment_method text DEFAULT 'cash'::text NOT NULL,
    total_amount numeric DEFAULT 0 NOT NULL,
    wallet_account_id uuid,
    notes text,
    receipt_file_path text,
    status text DEFAULT 'completed'::text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.site_content (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    section_key text NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid
);


--
CREATE TABLE public.supplier_agent_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supplier_agent_id uuid NOT NULL,
    description text NOT NULL,
    quantity numeric DEFAULT 1 NOT NULL,
    unit_price numeric DEFAULT 0 NOT NULL,
    total_amount numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.supplier_agent_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supplier_agent_id uuid NOT NULL,
    amount numeric NOT NULL,
    payment_method text DEFAULT 'cash'::text,
    date date DEFAULT CURRENT_DATE NOT NULL,
    notes text,
    wallet_account_id uuid,
    recorded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    booking_id uuid,
    receipt_file_path text
);


--
CREATE TABLE public.supplier_agents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agent_name text NOT NULL,
    company_name text,
    phone text,
    address text,
    notes text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    contract_date date,
    contracted_hajji integer DEFAULT 0 NOT NULL,
    contracted_amount numeric DEFAULT 0 NOT NULL
);


--
CREATE TABLE public.supplier_contract_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supplier_id uuid NOT NULL,
    contract_id uuid NOT NULL,
    amount numeric NOT NULL,
    payment_method text DEFAULT 'cash'::text,
    payment_date date DEFAULT CURRENT_DATE NOT NULL,
    note text,
    wallet_account_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.supplier_contracts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supplier_id uuid NOT NULL,
    pilgrim_count integer DEFAULT 0 NOT NULL,
    contract_amount numeric DEFAULT 0 NOT NULL,
    total_paid numeric DEFAULT 0 NOT NULL,
    total_due numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.ticket_bookings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_no text DEFAULT public.gen_ticket_invoice_no() NOT NULL,
    staff_name text,
    passenger_name text NOT NULL,
    booking_ref text,
    vendor_name text,
    vendor_id uuid,
    billing_name text,
    client_reference text,
    issue_date date DEFAULT CURRENT_DATE NOT NULL,
    terms_of_charge text DEFAULT 'newly_issue'::text NOT NULL,
    customer_billing_amount numeric DEFAULT 0 NOT NULL,
    our_cost numeric DEFAULT 0 NOT NULL,
    received_amount numeric DEFAULT 0 NOT NULL,
    customer_due numeric DEFAULT 0 NOT NULL,
    profit numeric DEFAULT 0 NOT NULL,
    payment_status text DEFAULT 'due'::text NOT NULL,
    departure_date date,
    arrival_date date,
    route text,
    expected_collection_date date,
    remarks text,
    bill_correction_amount numeric,
    status text DEFAULT 'active'::text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE SEQUENCE public.ticket_invoice_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
CREATE TABLE public.ticket_refunds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_no text DEFAULT public.gen_refund_invoice_no() NOT NULL,
    ticket_booking_id uuid,
    staff_name text,
    passenger_name text NOT NULL,
    booking_ref text,
    vendor_name text,
    vendor_id uuid,
    billing_name text,
    client_reference text,
    refund_date date DEFAULT CURRENT_DATE NOT NULL,
    terms_of_charge text DEFAULT 'refund_charge'::text NOT NULL,
    billing_amount_was numeric DEFAULT 0 NOT NULL,
    customer_refund_charge numeric DEFAULT 0 NOT NULL,
    our_refund_charge numeric DEFAULT 0 NOT NULL,
    refund_back_from_vendor numeric DEFAULT 0 NOT NULL,
    credit_amount_to_client numeric DEFAULT 0 NOT NULL,
    ticket_costing_was numeric DEFAULT 0 NOT NULL,
    profit numeric DEFAULT 0 NOT NULL,
    bill_received numeric DEFAULT 0 NOT NULL,
    due numeric DEFAULT 0 NOT NULL,
    credit_status text DEFAULT 'pending'::text NOT NULL,
    route text,
    remarks text,
    wallet_account_id uuid,
    status text DEFAULT 'active'::text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE TABLE public.transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type text NOT NULL,
    category text NOT NULL,
    amount numeric NOT NULL,
    booking_id uuid,
    user_id uuid NOT NULL,
    date date DEFAULT CURRENT_DATE NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    payment_method text,
    customer_id uuid,
    reference text,
    debit numeric DEFAULT 0 NOT NULL,
    credit numeric DEFAULT 0 NOT NULL,
    source_type text DEFAULT 'other'::text NOT NULL,
    source_id uuid,
    CONSTRAINT transactions_type_check CHECK ((type = ANY (ARRAY['income'::text, 'expense'::text])))
);


--
CREATE TABLE public.user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role public.app_role DEFAULT 'user'::public.app_role NOT NULL
);


--
CREATE TABLE public.visa_applications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_no text DEFAULT public.gen_visa_invoice_no() NOT NULL,
    staff_name text,
    applicant_name text NOT NULL,
    passport_number text,
    country_name text NOT NULL,
    vendor_name text,
    vendor_id uuid,
    billing_name text,
    client_reference text,
    application_date date DEFAULT CURRENT_DATE NOT NULL,
    billing_amount numeric DEFAULT 0 NOT NULL,
    our_cost numeric DEFAULT 0 NOT NULL,
    received_amount numeric DEFAULT 0 NOT NULL,
    customer_due numeric DEFAULT 0 NOT NULL,
    profit numeric DEFAULT 0 NOT NULL,
    visa_status text DEFAULT 'pending'::text NOT NULL,
    payment_status text DEFAULT 'due'::text NOT NULL,
    submission_date date,
    vendor_delivery_date date,
    client_delivery_date date,
    expected_collection_date date,
    remarks text,
    status text DEFAULT 'active'::text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
CREATE SEQUENCE public.visa_invoice_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.admin_2fa_codes
    ADD CONSTRAINT admin_2fa_codes_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.admin_2fa
    ADD CONSTRAINT admin_2fa_pkey PRIMARY KEY (user_id);


--
ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.blog_posts
    ADD CONSTRAINT blog_posts_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.booking_documents
    ADD CONSTRAINT booking_documents_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.booking_members
    ADD CONSTRAINT booking_members_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.cancellation_policies
    ADD CONSTRAINT cancellation_policies_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.cms_versions
    ADD CONSTRAINT cms_versions_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.company_settings
    ADD CONSTRAINT company_settings_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.daily_cashbook
    ADD CONSTRAINT daily_cashbook_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.financial_summary
    ADD CONSTRAINT financial_summary_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.hotel_bookings
    ADD CONSTRAINT hotel_bookings_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.hotel_rooms
    ADD CONSTRAINT hotel_rooms_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.hotels
    ADD CONSTRAINT hotels_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.installment_plans
    ADD CONSTRAINT installment_plans_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.moallem_commission_payments
    ADD CONSTRAINT moallem_commission_payments_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.moallem_items
    ADD CONSTRAINT moallem_items_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.moallem_payments
    ADD CONSTRAINT moallem_payments_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.moallems
    ADD CONSTRAINT moallems_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.notification_logs
    ADD CONSTRAINT notification_logs_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.notification_settings
    ADD CONSTRAINT notification_settings_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.online_payment_sessions
    ADD CONSTRAINT online_payment_sessions_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.otp_codes
    ADD CONSTRAINT otp_codes_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.packages
    ADD CONSTRAINT packages_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.settlement_items
    ADD CONSTRAINT settlement_items_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.site_content
    ADD CONSTRAINT site_content_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.supplier_agent_items
    ADD CONSTRAINT supplier_agent_items_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.supplier_agent_payments
    ADD CONSTRAINT supplier_agent_payments_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.supplier_agents
    ADD CONSTRAINT supplier_agents_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.supplier_contract_payments
    ADD CONSTRAINT supplier_contract_payments_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.supplier_contracts
    ADD CONSTRAINT supplier_contracts_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.ticket_bookings
    ADD CONSTRAINT ticket_bookings_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.ticket_refunds
    ADD CONSTRAINT ticket_refunds_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
ALTER TABLE ONLY public.visa_applications
    ADD CONSTRAINT visa_applications_pkey PRIMARY KEY (id);


--
