-- Foreign-key indexes keep operational joins, retention jobs and RLS lookups fast as data grows.
create index if not exists audit_logs_actor_id_idx on public.audit_logs (actor_id);
create index if not exists booking_services_service_id_idx on public.booking_services (service_id);
create index if not exists booking_services_staff_id_idx on public.booking_services (staff_id);
create index if not exists expenses_created_by_idx on public.expenses (created_by);
create index if not exists inventory_movements_created_by_idx on public.inventory_movements (created_by);
create index if not exists invoice_lines_invoice_id_idx on public.invoice_lines (invoice_id);
create index if not exists invoice_lines_service_id_idx on public.invoice_lines (service_id);
create index if not exists invoices_bank_account_id_idx on public.invoices (bank_account_id);
create index if not exists invoices_created_by_idx on public.invoices (created_by);
create index if not exists invoices_customer_id_idx on public.invoices (customer_id);
create index if not exists landing_content_updated_by_idx on public.landing_content (updated_by);
create index if not exists landing_media_created_by_idx on public.landing_media (created_by);
create index if not exists payments_bank_account_id_idx on public.payments (bank_account_id);
create index if not exists payments_invoice_id_idx on public.payments (invoice_id);
create index if not exists service_staff_staff_id_idx on public.service_staff (staff_id);
create index if not exists staff_commission_rules_updated_by_idx on public.staff_commission_rules (updated_by);
