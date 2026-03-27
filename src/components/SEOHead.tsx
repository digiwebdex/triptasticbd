import { Helmet } from "react-helmet-async";

interface SEOHeadProps {
  title?: string;
  description?: string;
  keywords?: string;
  canonicalUrl?: string;
  ogImage?: string;
  ogType?: "website" | "article" | "product";
  noIndex?: boolean;
  jsonLd?: Record<string, any> | Record<string, any>[];
  lang?: string;
}

const SITE_NAME = "Manasik Travel Hub";
const DEFAULT_DESCRIPTION =
  "মানাসিক ট্রাভেল হাব - হজ্জ, উমরাহ ও ভিসা সেবায় বাংলাদেশের বিশ্বস্ত প্রতিষ্ঠান। Trusted Hajj, Umrah, Visa & Tour services from Bangladesh.";
const DEFAULT_OG_IMAGE = "/assets/logo.png";
const BASE_URL = "https://manasiktravelhub.com";

export default function SEOHead({
  title,
  description = DEFAULT_DESCRIPTION,
  keywords,
  canonicalUrl,
  ogImage = DEFAULT_OG_IMAGE,
  ogType = "website",
  noIndex = false,
  jsonLd,
  lang = "bn",
}: SEOHeadProps) {
  const fullTitle = title ? `${title} | ${SITE_NAME}` : SITE_NAME;
  const fullOgImage = ogImage.startsWith("http") ? ogImage : `${BASE_URL}${ogImage}`;
  const canonical = canonicalUrl
    ? canonicalUrl.startsWith("http")
      ? canonicalUrl
      : `${BASE_URL}${canonicalUrl}`
    : undefined;

  const jsonLdArray = jsonLd
    ? Array.isArray(jsonLd)
      ? jsonLd
      : [jsonLd]
    : [];

  return (
    <Helmet>
      <html lang={lang} />
      <title>{fullTitle}</title>
      <meta name="description" content={description} />
      {keywords && <meta name="keywords" content={keywords} />}
      {noIndex && <meta name="robots" content="noindex, nofollow" />}
      {canonical && <link rel="canonical" href={canonical} />}

      {/* Open Graph */}
      <meta property="og:title" content={fullTitle} />
      <meta property="og:description" content={description} />
      <meta property="og:type" content={ogType} />
      <meta property="og:image" content={fullOgImage} />
      <meta property="og:site_name" content={SITE_NAME} />
      {canonical && <meta property="og:url" content={canonical} />}

      {/* Twitter Card */}
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={fullTitle} />
      <meta name="twitter:description" content={description} />
      <meta name="twitter:image" content={fullOgImage} />

      {/* JSON-LD Structured Data */}
      {jsonLdArray.map((ld, i) => (
        <script key={i} type="application/ld+json">
          {JSON.stringify(ld)}
        </script>
      ))}
    </Helmet>
  );
}

// ── Reusable JSON-LD generators ──

export function organizationJsonLd() {
  return {
    "@context": "https://schema.org",
    "@type": "TravelAgency",
    name: SITE_NAME,
    url: BASE_URL,
    logo: `${BASE_URL}/assets/logo.png`,
    description: DEFAULT_DESCRIPTION,
    address: {
      "@type": "PostalAddress",
      streetAddress: "595/1, Milk Vita Road, Three-way Intersection, Dewla",
      addressLocality: "Tangail Sadar, Tangail",
      addressCountry: "BD",
    },
    telephone: "+8801711993562",
    sameAs: ["https://www.facebook.com/profile.php?id=61585173125908"],
    contactPoint: {
      "@type": "ContactPoint",
      telephone: "+8801711993562",
      contactType: "customer service",
      availableLanguage: ["Bengali", "English"],
    },
  };
}

export function breadcrumbJsonLd(items: { name: string; url: string }[]) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((item, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: item.name,
      item: item.url.startsWith("http") ? item.url : `${BASE_URL}${item.url}`,
    })),
  };
}

export function productJsonLd(pkg: {
  name: string;
  description?: string;
  price: number;
  image?: string;
  url: string;
}) {
  return {
    "@context": "https://schema.org",
    "@type": "Product",
    name: pkg.name,
    description: pkg.description || "",
    image: pkg.image || `${BASE_URL}/assets/logo.png`,
    url: pkg.url.startsWith("http") ? pkg.url : `${BASE_URL}${pkg.url}`,
    offers: {
      "@type": "Offer",
      price: pkg.price,
      priceCurrency: "BDT",
      availability: "https://schema.org/InStock",
    },
  };
}

export function faqJsonLd(items: { question: string; answer: string }[]) {
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: items.map((item) => ({
      "@type": "Question",
      name: item.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.answer,
      },
    })),
  };
}
