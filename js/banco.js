/* =========================================================
   LIGAÇÃO COM O SUPABASE (usada por todas as páginas)

   Aqui ficam só o endereço do projeto e a chave PÚBLICA.
   Essa chave foi feita para ficar no site: sozinha ela não abre
   nada, quem protege os seus dados são as trancas (RLS) do banco.sql.

   NUNCA coloque aqui a chave secreta (service_role ou sb_secret).

   Toda página que usa o banco precisa carregar, nesta ordem:
   1. https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2
   2. este arquivo
   ========================================================= */
window.SUPABASE_URL = "https://odgidcbqjvbmobrdvmej.supabase.co";
window.SUPABASE_CHAVE = "sb_publishable_VGWxgK5rir_XGXUK-nvk2g_KEiVSLNL";

/* window.banco é o "atalho" que as páginas usam para falar com o Supabase.
   Se a biblioteca do Supabase não carregar (sem internet, por exemplo),
   ele fica vazio e cada página segue funcionando do jeito dela. */
window.banco = null;
try {
  if (window.supabase && typeof window.supabase.createClient === "function") {
    window.banco = window.supabase.createClient(window.SUPABASE_URL, window.SUPABASE_CHAVE);
  }
} catch (e) {
  window.banco = null;
}
