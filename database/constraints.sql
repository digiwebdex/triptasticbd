-- Generated from Supabase pg_dump
-- Apply order: schema.sql -> functions.sql -> data.sql -> indexes.sql -> constraints.sql

ALTER TABLE ONLY public.booking_documents
    ADD CONSTRAINT booking_documents_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.booking_documents
    ADD CONSTRAINT booking_documents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.booking_members
    ADD CONSTRAINT booking_members_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.booking_members
    ADD CONSTRAINT booking_members_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.packages(id);


--
ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_installment_plan_id_fkey FOREIGN KEY (installment_plan_id) REFERENCES public.installment_plans(id);


--
ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_moallem_id_fkey FOREIGN KEY (moallem_id) REFERENCES public.moallems(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.packages(id);


--
ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_supplier_agent_id_fkey FOREIGN KEY (supplier_agent_id) REFERENCES public.supplier_agents(id);


--
ALTER TABLE ONLY public.company_settings
    ADD CONSTRAINT company_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
ALTER TABLE ONLY public.daily_cashbook
    ADD CONSTRAINT daily_cashbook_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.packages(id);


--
ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
ALTER TABLE ONLY public.hotel_bookings
    ADD CONSTRAINT hotel_bookings_hotel_id_fkey FOREIGN KEY (hotel_id) REFERENCES public.hotels(id);


--
ALTER TABLE ONLY public.hotel_bookings
    ADD CONSTRAINT hotel_bookings_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.hotel_rooms(id);


--
ALTER TABLE ONLY public.hotel_bookings
    ADD CONSTRAINT hotel_bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.hotel_rooms
    ADD CONSTRAINT hotel_rooms_hotel_id_fkey FOREIGN KEY (hotel_id) REFERENCES public.hotels(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.moallem_commission_payments
    ADD CONSTRAINT moallem_commission_payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.moallem_commission_payments
    ADD CONSTRAINT moallem_commission_payments_moallem_id_fkey FOREIGN KEY (moallem_id) REFERENCES public.moallems(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.moallem_commission_payments
    ADD CONSTRAINT moallem_commission_payments_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
ALTER TABLE ONLY public.moallem_items
    ADD CONSTRAINT moallem_items_moallem_id_fkey FOREIGN KEY (moallem_id) REFERENCES public.moallems(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.moallem_payments
    ADD CONSTRAINT moallem_payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.moallem_payments
    ADD CONSTRAINT moallem_payments_moallem_id_fkey FOREIGN KEY (moallem_id) REFERENCES public.moallems(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.moallem_payments
    ADD CONSTRAINT moallem_payments_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
ALTER TABLE ONLY public.notification_logs
    ADD CONSTRAINT notification_logs_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.notification_logs
    ADD CONSTRAINT notification_logs_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.notification_settings
    ADD CONSTRAINT notification_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
ALTER TABLE ONLY public.online_payment_sessions
    ADD CONSTRAINT online_payment_sessions_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
ALTER TABLE ONLY public.online_payment_sessions
    ADD CONSTRAINT online_payment_sessions_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(id);


--
ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_policy_id_fkey FOREIGN KEY (policy_id) REFERENCES public.cancellation_policies(id);


--
ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
ALTER TABLE ONLY public.settlement_items
    ADD CONSTRAINT settlement_items_settlement_id_fkey FOREIGN KEY (settlement_id) REFERENCES public.settlements(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
ALTER TABLE ONLY public.supplier_agent_items
    ADD CONSTRAINT supplier_agent_items_supplier_agent_id_fkey FOREIGN KEY (supplier_agent_id) REFERENCES public.supplier_agents(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.supplier_agent_payments
    ADD CONSTRAINT supplier_agent_payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.supplier_agent_payments
    ADD CONSTRAINT supplier_agent_payments_supplier_agent_id_fkey FOREIGN KEY (supplier_agent_id) REFERENCES public.supplier_agents(id);


--
ALTER TABLE ONLY public.supplier_agent_payments
    ADD CONSTRAINT supplier_agent_payments_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
ALTER TABLE ONLY public.supplier_contract_payments
    ADD CONSTRAINT supplier_contract_payments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.supplier_contracts(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.supplier_contract_payments
    ADD CONSTRAINT supplier_contract_payments_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier_agents(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.supplier_contract_payments
    ADD CONSTRAINT supplier_contract_payments_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
ALTER TABLE ONLY public.supplier_contracts
    ADD CONSTRAINT supplier_contracts_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier_agents(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.ticket_bookings
    ADD CONSTRAINT ticket_bookings_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.supplier_agents(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.ticket_refunds
    ADD CONSTRAINT ticket_refunds_ticket_booking_id_fkey FOREIGN KEY (ticket_booking_id) REFERENCES public.ticket_bookings(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.ticket_refunds
    ADD CONSTRAINT ticket_refunds_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.supplier_agents(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.ticket_refunds
    ADD CONSTRAINT ticket_refunds_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
ALTER TABLE ONLY public.visa_applications
    ADD CONSTRAINT visa_applications_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.supplier_agents(id) ON DELETE SET NULL;


--
