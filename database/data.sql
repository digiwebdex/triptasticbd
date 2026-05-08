--
-- PostgreSQL database dump
--

\restrict tPLsxwwBsObmiA5XzJC969MjGxliB4rZ1WiJkLNq3q1ENXcAikLKaFoTrCidIg5

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9

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
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.accounts DISABLE TRIGGER ALL;

COPY public.accounts (id, name, type, balance, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.accounts ENABLE TRIGGER ALL;

--
-- Data for Name: admin_2fa; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.admin_2fa DISABLE TRIGGER ALL;

COPY public.admin_2fa (user_id, sms_enabled, sms_phone, totp_enabled, totp_secret, totp_secret_pending, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.admin_2fa ENABLE TRIGGER ALL;

--
-- Data for Name: admin_2fa_codes; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.admin_2fa_codes DISABLE TRIGGER ALL;

COPY public.admin_2fa_codes (id, user_id, code, expires_at, verified, created_at) FROM stdin;
\.


ALTER TABLE public.admin_2fa_codes ENABLE TRIGGER ALL;

--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs DISABLE TRIGGER ALL;

COPY public.audit_logs (id, created_at, actor_id, actor_email, actor_role, action, entity_type, entity_id, method, path, status_code, ip_address, user_agent, changes, metadata) FROM stdin;
\.


ALTER TABLE public.audit_logs ENABLE TRIGGER ALL;

--
-- Data for Name: blog_posts; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.blog_posts DISABLE TRIGGER ALL;

COPY public.blog_posts (id, title, slug, content, excerpt, image_url, status, author_id, tags, published_at, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.blog_posts ENABLE TRIGGER ALL;

--
-- Data for Name: installment_plans; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.installment_plans DISABLE TRIGGER ALL;

COPY public.installment_plans (id, name, num_installments, description, is_active, created_at) FROM stdin;
\.


ALTER TABLE public.installment_plans ENABLE TRIGGER ALL;

--
-- Data for Name: moallems; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.moallems DISABLE TRIGGER ALL;

COPY public.moallems (id, name, phone, address, nid_number, contract_date, notes, status, created_at, updated_at, total_deposit, total_due, contracted_hajji, contracted_amount) FROM stdin;
\.


ALTER TABLE public.moallems ENABLE TRIGGER ALL;

--
-- Data for Name: packages; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.packages DISABLE TRIGGER ALL;

COPY public.packages (id, name, type, description, price, duration_days, features, image_url, is_active, created_at, updated_at, start_date, services, expiry_date, status, show_on_website, rating, highlight_tag) FROM stdin;
6149ff7f-9628-4247-b1b3-1dd1ac2ed221	Premium Hajj Package	hajj	Complete Hajj package with premium hotels near Haram, expert guidance, full pilgrimage support and all logistics handled end-to-end.	850000.00	35	["Premium 5-star hotels near Haram", "Direct flights", "Trained Bangladeshi guides", "All ground transportation", "Visa & insurance included", "Pre-departure training"]	\N	t	2026-05-02 19:21:08.392661+00	2026-05-02 19:21:08.392661+00	\N	[]	\N	active	t	5.0	Most Popular
b94e7299-144b-4a0b-87d8-77923180345b	Premium Umrah Package	umrah	Year-round Umrah packages for individuals, families and groups with flexible departures and premium accommodation.	185000.00	14	["4 & 5-star hotels", "Direct & transit flight options", "Visa processing", "Ziyara tours included", "24/7 on-ground support"]	\N	t	2026-05-02 19:21:08.392661+00	2026-05-02 19:21:08.392661+00	\N	[]	\N	active	t	4.9	Best Seller
da0a9870-3082-4bbf-ac58-fd8e00c93aab	International Tour Package	tour	Curated holidays to Asia, Europe, Middle East and beyond — fully managed itineraries for couples, families and groups.	95000.00	7	["Hand-picked destinations", "Hotel + flight + transfers", "Sightseeing & guides", "Customisable itineraries", "Group discounts available"]	\N	t	2026-05-02 19:21:08.392661+00	2026-05-02 19:21:08.392661+00	\N	[]	\N	active	t	4.8	\N
45e3b04e-21f8-4316-8393-c55007d07f61	Domestic & International Air Tickets	air_ticket	Best-fare air tickets across all major airlines with flexible booking, rescheduling and 24/7 support.	25000.00	\N	["All major airlines", "Lowest available fares", "Free rescheduling support", "Group fare booking", "Web check-in assistance"]	\N	t	2026-05-02 19:21:08.392661+00	2026-05-02 19:21:08.392661+00	\N	[]	\N	active	t	4.9	\N
f9468b10-4af9-414d-8ace-2dd5442630ac	Tourist Visa	visa	Smooth tourist visa processing for popular destinations worldwide — Schengen, UK, USA, Canada, Thailand, Malaysia, UAE and more.	5000.00	\N	["Document checklist", "Application drafting", "Appointment booking", "Interview preparation", "High approval rate"]	\N	t	2026-05-02 19:21:08.392661+00	2026-05-02 19:21:08.392661+00	\N	[]	\N	active	t	4.8	\N
14345fad-56c9-48e5-bf26-07bb3e0129f8	Business Visa	visa	Professional business visa support including invitation letters, company documentation and end-to-end embassy coordination.	8000.00	\N	["Invitation letter assistance", "Corporate documentation", "Multi-entry options", "Express processing available", "Fast-track appointments"]	\N	t	2026-05-02 19:21:08.392661+00	2026-05-02 19:21:08.392661+00	\N	[]	\N	active	t	4.8	\N
0fa3f0d3-a2b7-4bcb-beaf-c3134435efc8	Medical Visa	visa	Medical visa arrangements with hospital appointments, treatment letters and full attendant visa support.	7000.00	\N	["Hospital appointment booking", "Treatment letter coordination", "Attendant visa included", "India, Thailand, Singapore", "Travel & accommodation help"]	\N	t	2026-05-02 19:21:08.392661+00	2026-05-02 19:21:08.392661+00	\N	[]	\N	active	t	4.9	\N
40e16ce8-bd22-4f8e-a541-2bf91077811b	Work Visa	visa	End-to-end work visa processing for global job opportunities with verified employers and complete legal documentation.	35000.00	\N	["Verified employer matching", "Skill-based job search", "Document attestation", "Embassy interview prep", "Pre-departure orientation"]	\N	t	2026-05-02 19:21:08.392661+00	2026-05-02 19:21:08.392661+00	\N	[]	\N	active	t	4.7	\N
8f443194-cb5d-465c-875e-a8c3d1bf3438	Domestic Air Ambulance	emergency	Rapid medical evacuation within Bangladesh with fully equipped helicopters/aircraft and ICU-trained medical crew.	350000.00	\N	["24/7 rapid response", "ICU-equipped aircraft", "Trained medical crew", "Hospital-to-hospital transfer", "Insurance coordination"]	\N	t	2026-05-02 19:21:08.392661+00	2026-05-02 19:21:08.392661+00	\N	[]	\N	active	t	5.0	Emergency
3f60ce00-7fb4-424b-ab9a-5a846312d5eb	International Air Ambulance	emergency	International medical evacuation to India, Thailand, Singapore and beyond with full medical care during transit.	1500000.00	\N	["Global coverage", "Long-range medical jets", "Doctor + nurse on board", "Embassy clearance support", "End-to-end coordination"]	\N	t	2026-05-02 19:21:08.392661+00	2026-05-02 19:21:08.392661+00	\N	[]	\N	active	t	5.0	Emergency
ba659e05-ac41-481d-9bdb-c2499e10cb01	Economy Hajj Package	hajj	বাজেট-ফ্রেন্ডলি হজ্জ প্যাকেজ সব মৌলিক সুবিধা সহ	650000.00	40	["মক্কায় ৩-স্টার হোটেল", "মদিনায় ৩-স্টার হোটেল", "ইকোনমি ফ্লাইট", "অভিজ্ঞ মুয়াল্লিম গাইড", "সকল পরিবহন অন্তর্ভুক্ত"]	\N	t	2026-05-02 20:12:19.627769+00	2026-05-02 20:12:19.627769+00	\N	["ভিসা", "হোটেল", "ফ্লাইট", "খাবার"]	\N	active	t	4.8	Best Value
75e506f9-f5db-4f44-a863-1293b3b3e897	Standard Hajj Package	hajj	মধ্যম বাজেটে সর্বোত্তম হজ্জ অভিজ্ঞতা	750000.00	38	["হারামের কাছে ৪-স্টার হোটেল", "মদিনায় ৪-স্টার হোটেল", "ডাইরেক্ট ফ্লাইট", "ডেডিকেটেড গাইড", "৩ বেলা খাবার", "মিনায় উন্নত তাঁবু"]	\N	t	2026-05-02 20:12:19.627769+00	2026-05-02 20:12:19.627769+00	\N	["ভিসা", "হোটেল", "ফ্লাইট", "খাবার", "জিয়ারত"]	\N	active	t	4.9	Popular
6638a35c-3eef-43bc-a8bb-8a7d5003faec	Economy Umrah Package	umrah	সাশ্রয়ী মূল্যে সম্পূর্ণ উমরাহ প্যাকেজ	125000.00	10	["মক্কায় ৩-স্টার হোটেল", "মদিনায় ৩-স্টার হোটেল", "ইকোনমি ফ্লাইট", "ভিসা প্রসেসিং", "এয়ারপোর্ট ট্রান্সফার"]	\N	t	2026-05-02 20:12:19.627769+00	2026-05-02 20:12:19.627769+00	\N	["ভিসা", "হোটেল", "ফ্লাইট"]	\N	active	t	4.7	Affordable
bdc309e5-7041-492a-b05c-031eba0958c2	Family Umrah Package	umrah	পরিবারের জন্য বিশেষ উমরাহ প্যাকেজ	165000.00	12	["হারামের ৫০০মিটারে হোটেল", "ফ্যামিলি রুম", "৩ বেলা বুফে খাবার", "জিয়ারত ট্যুর", "অভিজ্ঞ আলেম গাইড", "এয়ারপোর্ট পিকআপ"]	\N	t	2026-05-02 20:12:19.627769+00	2026-05-02 20:12:19.627769+00	\N	["ভিসা", "হোটেল", "ফ্লাইট", "খাবার", "জিয়ারত"]	\N	active	t	4.9	Family Choice
f3cb9ac8-7cc4-4a3d-9d8a-267a7605d042	Dubai Tour Package	tour	বিলাসবহুল দুবাই ট্যুর প্যাকেজ পরিবারের জন্য	75000.00	5	["৪-স্টার হোটেল", "বুর্জ খলিফা টিকেট", "ডেজার্ট সাফারি", "দুবাই মল ভিজিট", "সকল ট্রান্সফার অন্তর্ভুক্ত"]	\N	t	2026-05-02 20:12:19.627769+00	2026-05-02 20:12:19.627769+00	\N	["ভিসা", "হোটেল", "ফ্লাইট", "সাইটসিইং"]	\N	active	t	4.8	Hot Deal
0f9b50c3-e5b7-42e8-be24-ef2f5eb4f875	Turkey Tour Package	tour	ঐতিহাসিক তুরস্ক ভ্রমণ প্যাকেজ	110000.00	8	["ইস্তানবুল ৪-স্টার হোটেল", "বসফরাস ক্রুজ", "ব্লু মস্ক ভিজিট", "কাপাডোসিয়া ট্যুর", "সকল প্রবেশ মূল্য অন্তর্ভুক্ত"]	\N	t	2026-05-02 20:12:19.627769+00	2026-05-02 20:12:19.627769+00	\N	["ভিসা", "হোটেল", "ফ্লাইট", "গাইড"]	\N	active	t	4.9	New
a798d88a-993a-4a5d-8eaa-5eaf5335bfa9	International Air Ticket Booking	air_ticket	Best fares on international flights to Saudi Arabia, UAE, Malaysia, Turkey, UK, Canada, Japan and more — 24/7 booking support.	45000.00	\N	["Best Price Guarantee", "24/7 Support", "Instant Confirmation", "Multi-City Routes", "All Major Airlines"]	\N	t	2026-05-02 20:32:35.436075+00	2026-05-02 20:32:35.436075+00	\N	["Economy/Business/First Class", "Group Booking Discount", "Free Cancellation Window", "Date Change Assistance", "E-Ticket Delivery"]	\N	active	t	4.9	Best Price
3030ac14-f3a9-4980-82ed-f050eab76465	Group & Corporate Air Tickets	air_ticket	Special group fares and corporate travel solutions with dedicated account manager and flexible payment terms.	22000.00	\N	["Group Discount up to 15%", "Dedicated Account Manager", "Flexible Payment", "Priority Boarding", "Free Seat Selection"]	\N	t	2026-05-02 20:32:35.436075+00	2026-05-02 20:32:35.436075+00	\N	["10+ Passenger Discount", "Corporate Invoicing", "Travel Itinerary Planning", "Visa Assistance", "Hotel + Flight Combo"]	\N	active	t	4.8	Group Deal
72c8dc9b-ee92-4cb9-8bb4-d8b54b198687	Medical Evacuation Service	emergency	Critical care medical evacuation with ICU-equipped air ambulance, doctor escort and worldwide hospital coordination.	950000.00	\N	["ICU Equipped Aircraft", "Doctor & Nurse Escort", "24/7 Activation", "Worldwide Coverage", "Hospital-to-Hospital Transfer"]	\N	t	2026-05-02 20:32:35.436075+00	2026-05-02 20:32:35.436075+00	\N	["Ground Ambulance Coordination", "Insurance Documentation", "Visa Fast-Track", "Family Companion Seat", "Real-time Patient Updates"]	\N	active	t	5.0	Critical Care
\.


ALTER TABLE public.packages ENABLE TRIGGER ALL;

--
-- Data for Name: supplier_agents; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.supplier_agents DISABLE TRIGGER ALL;

COPY public.supplier_agents (id, agent_name, company_name, phone, address, notes, status, created_at, updated_at, contract_date, contracted_hajji, contracted_amount) FROM stdin;
\.


ALTER TABLE public.supplier_agents ENABLE TRIGGER ALL;

--
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.bookings DISABLE TRIGGER ALL;

COPY public.bookings (id, tracking_id, user_id, package_id, installment_plan_id, total_amount, paid_amount, status, num_travelers, notes, created_at, updated_at, guest_name, guest_phone, guest_email, guest_address, guest_passport, due_amount, moallem_id, supplier_agent_id, cost_price_per_person, total_cost, selling_price_per_person, extra_expense, profit_amount, paid_to_supplier, supplier_due, paid_by_moallem, moallem_due, commission_per_person, total_commission, commission_paid, commission_due, booking_type, discount) FROM stdin;
\.


ALTER TABLE public.bookings ENABLE TRIGGER ALL;

--
-- Data for Name: booking_documents; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.booking_documents DISABLE TRIGGER ALL;

COPY public.booking_documents (id, booking_id, user_id, document_type, file_name, file_path, file_size, created_at) FROM stdin;
\.


ALTER TABLE public.booking_documents ENABLE TRIGGER ALL;

--
-- Data for Name: booking_members; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.booking_members DISABLE TRIGGER ALL;

COPY public.booking_members (id, booking_id, full_name, passport_number, package_id, selling_price, discount, final_price, created_at) FROM stdin;
\.


ALTER TABLE public.booking_members ENABLE TRIGGER ALL;

--
-- Data for Name: cancellation_policies; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.cancellation_policies DISABLE TRIGGER ALL;

COPY public.cancellation_policies (id, name, description, refund_type, refund_value, min_days_before_departure, is_default, is_active, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.cancellation_policies ENABLE TRIGGER ALL;

--
-- Data for Name: cms_versions; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.cms_versions DISABLE TRIGGER ALL;

COPY public.cms_versions (id, section_key, content, updated_by, created_at, note) FROM stdin;
\.


ALTER TABLE public.cms_versions ENABLE TRIGGER ALL;

--
-- Data for Name: company_settings; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.company_settings DISABLE TRIGGER ALL;

COPY public.company_settings (id, setting_key, setting_value, updated_at, updated_by) FROM stdin;
\.


ALTER TABLE public.company_settings ENABLE TRIGGER ALL;

--
-- Data for Name: daily_cashbook; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.daily_cashbook DISABLE TRIGGER ALL;

COPY public.daily_cashbook (id, date, type, description, amount, category, wallet_account_id, payment_method, notes, created_by, created_at) FROM stdin;
\.


ALTER TABLE public.daily_cashbook ENABLE TRIGGER ALL;

--
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.expenses DISABLE TRIGGER ALL;

COPY public.expenses (id, title, amount, category, booking_id, date, note, created_at, customer_id, package_id, expense_type, wallet_account_id) FROM stdin;
\.


ALTER TABLE public.expenses ENABLE TRIGGER ALL;

--
-- Data for Name: financial_summary; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.financial_summary DISABLE TRIGGER ALL;

COPY public.financial_summary (id, total_income, total_expense, net_profit, updated_at) FROM stdin;
\.


ALTER TABLE public.financial_summary ENABLE TRIGGER ALL;

--
-- Data for Name: hotels; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.hotels DISABLE TRIGGER ALL;

COPY public.hotels (id, name, location, city, description, star_rating, distance_to_haram, amenities, image_url, gallery, is_active, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.hotels ENABLE TRIGGER ALL;

--
-- Data for Name: hotel_rooms; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.hotel_rooms DISABLE TRIGGER ALL;

COPY public.hotel_rooms (id, hotel_id, name, description, capacity, price_per_night, amenities, image_url, is_available, created_at) FROM stdin;
\.


ALTER TABLE public.hotel_rooms ENABLE TRIGGER ALL;

--
-- Data for Name: hotel_bookings; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.hotel_bookings DISABLE TRIGGER ALL;

COPY public.hotel_bookings (id, user_id, hotel_id, room_id, check_in, check_out, guests, total_price, status, notes, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.hotel_bookings ENABLE TRIGGER ALL;

--
-- Data for Name: moallem_commission_payments; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.moallem_commission_payments DISABLE TRIGGER ALL;

COPY public.moallem_commission_payments (id, moallem_id, booking_id, amount, payment_method, date, notes, wallet_account_id, recorded_by, created_at) FROM stdin;
\.


ALTER TABLE public.moallem_commission_payments ENABLE TRIGGER ALL;

--
-- Data for Name: moallem_items; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.moallem_items DISABLE TRIGGER ALL;

COPY public.moallem_items (id, moallem_id, description, quantity, unit_price, total_amount, created_at) FROM stdin;
\.


ALTER TABLE public.moallem_items ENABLE TRIGGER ALL;

--
-- Data for Name: moallem_payments; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.moallem_payments DISABLE TRIGGER ALL;

COPY public.moallem_payments (id, moallem_id, amount, payment_method, date, notes, wallet_account_id, recorded_by, created_at, booking_id, receipt_file_path) FROM stdin;
\.


ALTER TABLE public.moallem_payments ENABLE TRIGGER ALL;

--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.payments DISABLE TRIGGER ALL;

COPY public.payments (id, booking_id, user_id, amount, installment_number, payment_method, status, due_date, paid_at, notes, created_at, transaction_id, customer_id, wallet_account_id, receipt_file_path) FROM stdin;
\.


ALTER TABLE public.payments ENABLE TRIGGER ALL;

--
-- Data for Name: notification_logs; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.notification_logs DISABLE TRIGGER ALL;

COPY public.notification_logs (id, user_id, booking_id, payment_id, event_type, channel, recipient, subject, message, status, error_detail, sent_by, created_at) FROM stdin;
\.


ALTER TABLE public.notification_logs ENABLE TRIGGER ALL;

--
-- Data for Name: notification_settings; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.notification_settings DISABLE TRIGGER ALL;

COPY public.notification_settings (id, event_key, event_label, enabled, email_enabled, sms_enabled, updated_at, updated_by) FROM stdin;
\.


ALTER TABLE public.notification_settings ENABLE TRIGGER ALL;

--
-- Data for Name: online_payment_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.online_payment_sessions DISABLE TRIGGER ALL;

COPY public.online_payment_sessions (id, tran_id, booking_id, user_id, customer_phone, amount, currency, status, gateway, gateway_response, payment_id, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.online_payment_sessions ENABLE TRIGGER ALL;

--
-- Data for Name: otp_codes; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.otp_codes DISABLE TRIGGER ALL;

COPY public.otp_codes (id, phone, code, expires_at, verified, created_at) FROM stdin;
\.


ALTER TABLE public.otp_codes ENABLE TRIGGER ALL;

--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.profiles DISABLE TRIGGER ALL;

COPY public.profiles (id, user_id, full_name, phone, created_at, updated_at, address, passport_number, email, nid_number, date_of_birth, emergency_contact, notes, status) FROM stdin;
7c7e1f50-3e9a-4d1d-ad01-a47d4ca9e2be	ea742a1f-1451-45d6-8668-2a61403de923	Primary Admin	\N	2026-05-02 19:56:57.921434+00	2026-05-02 19:56:57.921434+00	\N	\N	admin@triptastic.com.bd	\N	\N	\N	\N	active
\.


ALTER TABLE public.profiles ENABLE TRIGGER ALL;

--
-- Data for Name: refunds; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.refunds DISABLE TRIGGER ALL;

COPY public.refunds (id, booking_id, policy_id, original_amount, refund_amount, deduction_amount, refund_method, wallet_account_id, reason, status, processed_by, processed_at, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.refunds ENABLE TRIGGER ALL;

--
-- Data for Name: settlements; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.settlements DISABLE TRIGGER ALL;

COPY public.settlements (id, settlement_no, settlement_date, payer_name, payment_method, total_amount, wallet_account_id, notes, receipt_file_path, status, created_by, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.settlements ENABLE TRIGGER ALL;

--
-- Data for Name: settlement_items; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.settlement_items DISABLE TRIGGER ALL;

COPY public.settlement_items (id, settlement_id, source_type, source_id, invoice_no, amount_applied, created_at) FROM stdin;
\.


ALTER TABLE public.settlement_items ENABLE TRIGGER ALL;

--
-- Data for Name: site_content; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.site_content DISABLE TRIGGER ALL;

COPY public.site_content (id, section_key, content, updated_at, updated_by) FROM stdin;
\.


ALTER TABLE public.site_content ENABLE TRIGGER ALL;

--
-- Data for Name: supplier_agent_items; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.supplier_agent_items DISABLE TRIGGER ALL;

COPY public.supplier_agent_items (id, supplier_agent_id, description, quantity, unit_price, total_amount, created_at) FROM stdin;
\.


ALTER TABLE public.supplier_agent_items ENABLE TRIGGER ALL;

--
-- Data for Name: supplier_agent_payments; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.supplier_agent_payments DISABLE TRIGGER ALL;

COPY public.supplier_agent_payments (id, supplier_agent_id, amount, payment_method, date, notes, wallet_account_id, recorded_by, created_at, booking_id, receipt_file_path) FROM stdin;
\.


ALTER TABLE public.supplier_agent_payments ENABLE TRIGGER ALL;

--
-- Data for Name: supplier_contracts; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.supplier_contracts DISABLE TRIGGER ALL;

COPY public.supplier_contracts (id, supplier_id, pilgrim_count, contract_amount, total_paid, total_due, created_at) FROM stdin;
\.


ALTER TABLE public.supplier_contracts ENABLE TRIGGER ALL;

--
-- Data for Name: supplier_contract_payments; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.supplier_contract_payments DISABLE TRIGGER ALL;

COPY public.supplier_contract_payments (id, supplier_id, contract_id, amount, payment_method, payment_date, note, wallet_account_id, created_by, created_at) FROM stdin;
\.


ALTER TABLE public.supplier_contract_payments ENABLE TRIGGER ALL;

--
-- Data for Name: ticket_bookings; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.ticket_bookings DISABLE TRIGGER ALL;

COPY public.ticket_bookings (id, invoice_no, staff_name, passenger_name, booking_ref, vendor_name, vendor_id, billing_name, client_reference, issue_date, terms_of_charge, customer_billing_amount, our_cost, received_amount, customer_due, profit, payment_status, departure_date, arrival_date, route, expected_collection_date, remarks, bill_correction_amount, status, created_by, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.ticket_bookings ENABLE TRIGGER ALL;

--
-- Data for Name: ticket_refunds; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.ticket_refunds DISABLE TRIGGER ALL;

COPY public.ticket_refunds (id, invoice_no, ticket_booking_id, staff_name, passenger_name, booking_ref, vendor_name, vendor_id, billing_name, client_reference, refund_date, terms_of_charge, billing_amount_was, customer_refund_charge, our_refund_charge, refund_back_from_vendor, credit_amount_to_client, ticket_costing_was, profit, bill_received, due, credit_status, route, remarks, wallet_account_id, status, created_by, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.ticket_refunds ENABLE TRIGGER ALL;

--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.transactions DISABLE TRIGGER ALL;

COPY public.transactions (id, type, category, amount, booking_id, user_id, date, note, created_at, payment_method, customer_id, reference, debit, credit, source_type, source_id) FROM stdin;
\.


ALTER TABLE public.transactions ENABLE TRIGGER ALL;

--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.user_roles DISABLE TRIGGER ALL;

COPY public.user_roles (id, user_id, role) FROM stdin;
9c5e04e4-e783-4ba4-9590-9a2a38a70683	ea742a1f-1451-45d6-8668-2a61403de923	admin
\.


ALTER TABLE public.user_roles ENABLE TRIGGER ALL;

--
-- Data for Name: visa_applications; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.visa_applications DISABLE TRIGGER ALL;

COPY public.visa_applications (id, invoice_no, staff_name, applicant_name, passport_number, country_name, vendor_name, vendor_id, billing_name, client_reference, application_date, billing_amount, our_cost, received_amount, customer_due, profit, visa_status, payment_status, submission_date, vendor_delivery_date, client_delivery_date, expected_collection_date, remarks, status, created_by, created_at, updated_at) FROM stdin;
\.


ALTER TABLE public.visa_applications ENABLE TRIGGER ALL;

--
-- Name: refund_invoice_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.refund_invoice_seq', 1, false);


--
-- Name: settlement_no_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.settlement_no_seq', 1, false);


--
-- Name: ticket_invoice_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ticket_invoice_seq', 1, false);


--
-- Name: visa_invoice_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.visa_invoice_seq', 1, false);


--
-- PostgreSQL database dump complete
--

\unrestrict tPLsxwwBsObmiA5XzJC969MjGxliB4rZ1WiJkLNq3q1ENXcAikLKaFoTrCidIg5

