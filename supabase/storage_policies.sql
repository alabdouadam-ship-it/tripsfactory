-- ============================================================================
-- storage_policies.sql — RLS policies on storage.objects, mirrored from the
-- source project. Run after the schema + buckets exist. Idempotent
-- (drop-then-create), and authoritative regardless of what migrations created.
--
-- Depends on functions/types from the schema: is_admin(),
-- can_read_chat_attachment(name), and (for the vestigial SuperAdmin policy)
-- has_role()/admin_role. If those were removed in your schema, drop the
-- corresponding policy below.
-- ============================================================================

-- ads ------------------------------------------------------------------------
drop policy if exists "Public Access" on storage.objects;
create policy "Public Access" on storage.objects for select to public
  using (bucket_id = 'ads');

drop policy if exists "Admins upload ads" on storage.objects;
create policy "Admins upload ads" on storage.objects for insert to authenticated
  with check (bucket_id = 'ads' and is_admin());

drop policy if exists "Admins update ads" on storage.objects;
create policy "Admins update ads" on storage.objects for update to authenticated
  using (bucket_id = 'ads' and is_admin())
  with check (bucket_id = 'ads' and is_admin());

drop policy if exists "Admins delete ads" on storage.objects;
create policy "Admins delete ads" on storage.objects for delete to authenticated
  using (bucket_id = 'ads' and is_admin());

-- avatars --------------------------------------------------------------------
drop policy if exists "Public can view avatars" on storage.objects;
create policy "Public can view avatars" on storage.objects for select to public
  using (bucket_id = 'avatars');

drop policy if exists "Authenticated users can upload avatars" on storage.objects;
create policy "Authenticated users can upload avatars" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and auth.uid() = owner);

drop policy if exists "Users can update their own avatars" on storage.objects;
create policy "Users can update their own avatars" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and auth.uid() = owner);

drop policy if exists "Users can delete their own avatars" on storage.objects;
create policy "Users can delete their own avatars" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and auth.uid() = owner);

-- user_documents (PRIVATE) ---------------------------------------------------
drop policy if exists "Authenticated can view own documents" on storage.objects;
create policy "Authenticated can view own documents" on storage.objects for select to authenticated
  using (bucket_id = 'user_documents' and (auth.uid() = owner or (select is_admin())));

drop policy if exists "Authenticated users can upload documents" on storage.objects;
create policy "Authenticated users can upload documents" on storage.objects for insert to authenticated
  with check (bucket_id = 'user_documents' and auth.uid() = owner);

drop policy if exists "Users can update their own documents" on storage.objects;
create policy "Users can update their own documents" on storage.objects for update to authenticated
  using (bucket_id = 'user_documents' and auth.uid() = owner);

drop policy if exists "Users can delete their own documents" on storage.objects;
create policy "Users can delete their own documents" on storage.objects for delete to authenticated
  using (bucket_id = 'user_documents' and auth.uid() = owner);

-- admin_exports (PRIVATE) ----------------------------------------------------
drop policy if exists "Admins read own export files" on storage.objects;
create policy "Admins read own export files" on storage.objects for select to public
  using (bucket_id = 'admin_exports' and (auth.uid())::text = (storage.foldername(name))[1]);

-- Vestigial: depends on has_role()/admin_role (collapsed to is_admin in 00053).
drop policy if exists "SuperAdmin reads all export files" on storage.objects;
create policy "SuperAdmin reads all export files" on storage.objects for select to public
  using (bucket_id = 'admin_exports' and has_role('super_admin'::admin_role));

-- chat-attachments (PRIVATE) -------------------------------------------------
drop policy if exists "chat_attach_insert_own" on storage.objects;
create policy "chat_attach_insert_own" on storage.objects for insert to authenticated
  with check (bucket_id = 'chat-attachments' and (storage.foldername(name))[1] = (auth.uid())::text);

drop policy if exists "chat_attach_select_participants" on storage.objects;
create policy "chat_attach_select_participants" on storage.objects for select to authenticated
  using (bucket_id = 'chat-attachments' and (owner = auth.uid() or is_admin() or can_read_chat_attachment(name)));
