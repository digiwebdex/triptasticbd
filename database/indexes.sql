-- Generated from Supabase pg_dump
-- Apply order: schema.sql -> functions.sql -> data.sql -> indexes.sql -> constraints.sql

CREATE INDEX idx_admin_2fa_codes_user ON public.admin_2fa_codes USING btree (user_id, created_at DESC);


--
CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
CREATE INDEX idx_audit_logs_actor ON public.audit_logs USING btree (actor_id);


--
CREATE INDEX idx_audit_logs_created_at ON public.audit_logs USING btree (created_at DESC);


--
CREATE INDEX idx_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
CREATE INDEX idx_blog_posts_slug ON public.blog_posts USING btree (slug);


--
CREATE INDEX idx_blog_posts_status ON public.blog_posts USING btree (status);


--
CREATE INDEX idx_cms_versions_section ON public.cms_versions USING btree (section_key, created_at DESC);


--
CREATE INDEX idx_expenses_category ON public.expenses USING btree (category);


--
CREATE INDEX idx_expenses_date ON public.expenses USING btree (date);


--
CREATE INDEX idx_notification_logs_booking ON public.notification_logs USING btree (booking_id);


--
CREATE INDEX idx_notification_logs_created ON public.notification_logs USING btree (created_at DESC);


--
CREATE INDEX idx_notification_logs_event ON public.notification_logs USING btree (event_type);


--
CREATE INDEX idx_notification_logs_user ON public.notification_logs USING btree (user_id);


--
CREATE INDEX idx_ops_booking ON public.online_payment_sessions USING btree (booking_id);


--
CREATE INDEX idx_ops_status ON public.online_payment_sessions USING btree (status);


--
CREATE INDEX idx_otp_codes_phone_expires ON public.otp_codes USING btree (phone, expires_at);


--
CREATE INDEX idx_packages_show_on_website ON public.packages USING btree (show_on_website);


--
CREATE INDEX idx_packages_status ON public.packages USING btree (status);


--
CREATE INDEX idx_profiles_status ON public.profiles USING btree (status);


--
CREATE INDEX idx_settlement_items_settlement ON public.settlement_items USING btree (settlement_id);


--
CREATE INDEX idx_settlement_items_source ON public.settlement_items USING btree (source_type, source_id);


--
CREATE INDEX idx_settlements_date ON public.settlements USING btree (settlement_date);


--
CREATE INDEX idx_settlements_no ON public.settlements USING btree (settlement_no);


--
CREATE INDEX idx_ticket_bookings_collection ON public.ticket_bookings USING btree (expected_collection_date) WHERE (payment_status <> 'paid'::text);


--
CREATE INDEX idx_ticket_bookings_invoice ON public.ticket_bookings USING btree (invoice_no);


--
CREATE INDEX idx_ticket_bookings_status ON public.ticket_bookings USING btree (payment_status, status);


--
CREATE INDEX idx_ticket_bookings_vendor ON public.ticket_bookings USING btree (vendor_id);


--
CREATE INDEX idx_ticket_refunds_booking ON public.ticket_refunds USING btree (ticket_booking_id);


--
CREATE INDEX idx_ticket_refunds_invoice ON public.ticket_refunds USING btree (invoice_no);


--
CREATE INDEX idx_transactions_booking_id ON public.transactions USING btree (booking_id);


--
CREATE INDEX idx_transactions_date ON public.transactions USING btree (date);


--
CREATE INDEX idx_transactions_source_id ON public.transactions USING btree (source_id);


--
CREATE INDEX idx_transactions_source_type ON public.transactions USING btree (source_type);


--
CREATE INDEX idx_transactions_type ON public.transactions USING btree (type);


--
CREATE INDEX idx_visa_applications_invoice ON public.visa_applications USING btree (invoice_no);


--
CREATE INDEX idx_visa_applications_status ON public.visa_applications USING btree (visa_status, payment_status, status);


--
