import { lazy, Suspense } from "react";
import Navbar from "@/components/Navbar";
import HeroSection from "@/components/HeroSection";
import ServicesSection from "@/components/ServicesSection";
import PackagesSection from "@/components/PackagesSection";
import FacilitiesSection from "@/components/FacilitiesSection";
import TypedPackageSection from "@/components/TypedPackageSection";
import Footer from "@/components/Footer";
import WhatsAppFloat from "@/components/WhatsAppFloat";
import BackToTop from "@/components/BackToTop";
import { useSectionVisibility } from "@/hooks/useSectionVisibility";
import SEOHead, { organizationJsonLd } from "@/components/SEOHead";
import { SiteContentProvider } from "@/hooks/useSiteContentProvider";

// Lazy load below-fold sections with retry for stale chunk errors
const lazyRetry = (importFn: () => Promise<any>) =>
  lazy(() =>
    importFn().catch(() => {
      window.location.reload();
      return importFn();
    })
  );

const GuidelineSection = lazyRetry(() => import("@/components/GuidelineSection"));
const VideoGuideSection = lazyRetry(() => import("@/components/VideoGuideSection"));
const GallerySection = lazyRetry(() => import("@/components/GallerySection"));
const TestimonialsSection = lazyRetry(() => import("@/components/TestimonialsSection"));
const AboutSection = lazyRetry(() => import("@/components/AboutSection"));
const ContactSection = lazyRetry(() => import("@/components/ContactSection"));

const SectionFallback = () => <div className="py-20" />;

const Index = () => {
  const { visibility, loading } = useSectionVisibility();
  const show = (key: string) => loading || visibility[key] !== false;

  return (
    <SiteContentProvider>
      <div className="min-h-screen bg-background">
        <SEOHead
          canonicalUrl="/"
          keywords="হজ্জ, উমরাহ, Hajj, Umrah, Visa, Tour, Bangladesh, ট্রিপ টেস্টিক, TRIP TASTIC, Tangail"
          jsonLd={organizationJsonLd()}
        />
        <Navbar />
        {show("hero") && <HeroSection />}
        {show("services") && <ServicesSection />}
        {show("facilities") && <FacilitiesSection />}
        {show("packages") && <PackagesSection />}
        {show("air_tickets") && (
          <TypedPackageSection packageType="air_ticket" sectionId="air-tickets" />
        )}
        {show("visa_services") && (
          <TypedPackageSection packageType="visa" sectionId="visa-services" />
        )}
        {show("tour_packages") && (
          <TypedPackageSection packageType="tour" sectionId="tour-packages" />
        )}
        {show("guidelines") && (
          <Suspense fallback={<SectionFallback />}>
            <GuidelineSection />
          </Suspense>
        )}
        {show("video_guide") && (
          <Suspense fallback={<SectionFallback />}>
            <VideoGuideSection />
          </Suspense>
        )}
        {show("gallery") && (
          <Suspense fallback={<SectionFallback />}>
            <GallerySection />
          </Suspense>
        )}
        {show("testimonials") && (
          <Suspense fallback={<SectionFallback />}>
            <TestimonialsSection />
          </Suspense>
        )}
        {show("about") && (
          <Suspense fallback={<SectionFallback />}>
            <AboutSection />
          </Suspense>
        )}
        {show("contact") && (
          <Suspense fallback={<SectionFallback />}>
            <ContactSection />
          </Suspense>
        )}
        <Footer />
        <WhatsAppFloat />
        <BackToTop />
      </div>
    </SiteContentProvider>
  );
};

export default Index;
