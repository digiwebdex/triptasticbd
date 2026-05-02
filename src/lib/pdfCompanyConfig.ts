import { supabase } from "@/lib/api";

// PDF Company Configuration - v2
export interface PdfCompanyConfig {
  company_name: string;
  tagline: string;
  phone: string;
  phone2: string;
  email: string;
  address: string;
  website: string;
  footer_text: string;
  footer_contact: string;
}

const DEFAULT_CONFIG: PdfCompanyConfig = {
  company_name: "TRIP TASTIC",
  tagline: "Hajj & Umrah Services",
  phone: "+880 1711-999910",
  phone2: "+880 1711-999920",
  email: "info@triptastic.com.bd",
  address: "Corporate Office: TRIP TASTIC, 595/1, Milk Vita Road, Three-Way Intersection, Dewla, Tangail Sadar, Tangail",
  website: "https://triptastic.com.bd",
  footer_text: "Thank you for choosing TRIP TASTIC!",
  footer_contact: "This is a computer-generated document. For queries: +880 1711-999910, +880 1711-999920 | info@triptastic.com.bd",
};

let cachedConfig: PdfCompanyConfig | null = null;
let cacheTime = 0;

export async function getPdfCompanyConfig(): Promise<PdfCompanyConfig> {
  if (cachedConfig && Date.now() - cacheTime < 5 * 60 * 1000) {
    return cachedConfig;
  }

  try {
    const { data } = await supabase
      .from("company_settings")
      .select("setting_value")
      .eq("setting_key", "pdf_company")
      .maybeSingle();

    const val = (data?.setting_value as any) || {};
    cachedConfig = {
      company_name: val.company_name || DEFAULT_CONFIG.company_name,
      tagline: val.tagline || DEFAULT_CONFIG.tagline,
      phone: val.phone || DEFAULT_CONFIG.phone,
      phone2: val.phone2 || DEFAULT_CONFIG.phone2,
      email: val.email || DEFAULT_CONFIG.email,
      address: val.address || DEFAULT_CONFIG.address,
      website: val.website || DEFAULT_CONFIG.website,
      footer_text: val.footer_text || DEFAULT_CONFIG.footer_text,
      footer_contact: val.footer_contact || DEFAULT_CONFIG.footer_contact,
    };
    cacheTime = Date.now();
    return cachedConfig;
  } catch {
    return DEFAULT_CONFIG;
  }
}

export function clearPdfConfigCache() {
  cachedConfig = null;
  cacheTime = 0;
}

export { DEFAULT_CONFIG };
