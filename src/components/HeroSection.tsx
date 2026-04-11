import { motion, AnimatePresence } from "framer-motion";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useState, useEffect, useCallback } from "react";
import heroBanner1 from "@/assets/hero-banner-1.jpg";
import { useBulkSiteContent } from "@/hooks/useSiteContentProvider";
import { useLanguage } from "@/i18n/LanguageContext";

const defaultSlides = [
  { image: heroBanner1, alt: "Manasik Travel Hub - Hajj & Umrah Services" },
];

const HeroSection = () => {
  const { data: content } = useBulkSiteContent("hero");
  const { language } = useLanguage();
  const [currentSlide, setCurrentSlide] = useState(0);

  // CMS-managed hero slides
  const cmsSlides = content?.hero_slides;
  const activeSlides = cmsSlides && cmsSlides.length > 0
    ? cmsSlides.map((s: any) => ({
        image: s.src || s.image,
        mobileImage: s.mobile_src || s.mobile_image || s.src || s.image,
        alt: s.alt || "Hero slide",
      }))
    : defaultSlides.map(s => ({ ...s, mobileImage: s.image }));

  useEffect(() => {
    if (activeSlides.length <= 1) return;
    const timer = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % activeSlides.length);
    }, 6000);
    return () => clearInterval(timer);
  }, [activeSlides.length]);

  const goTo = useCallback((dir: number) => {
    setCurrentSlide((prev) => (prev + dir + activeSlides.length) % activeSlides.length);
  }, [activeSlides.length]);

  return (
    <section
      id="hero"
      className="relative w-full overflow-hidden pt-24 sm:pt-24"
    >
      {/* Background Images with Ken Burns effect */}
      <AnimatePresence mode="wait">
        <motion.div
          key={currentSlide}
          initial={{ opacity: 0, scale: 1.08 }}
          animate={{ opacity: 1, scale: 1.02 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 1.2, ease: "easeOut" }}
        >
          {/* Desktop image */}
          <img
            src={activeSlides[currentSlide]?.image}
            alt={activeSlides[currentSlide]?.alt}
            className="hidden sm:block w-full h-auto"
            loading="eager"
            fetchPriority="high"
            decoding="async"
          />
          {/* Mobile image */}
          <img
            src={activeSlides[currentSlide]?.mobileImage}
            alt={activeSlides[currentSlide]?.alt}
            className="block sm:hidden w-full h-auto"
            loading="eager"
            fetchPriority="high"
            decoding="async"
          />
        </motion.div>
      </AnimatePresence>

      {/* Subtle gradient overlay for any future text readability */}
      <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-transparent to-black/40" />

      {/* Top accent line */}
      <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-gold z-10" />

      {/* Slide Navigation - only show if multiple slides */}
      {activeSlides.length > 1 && (
        <>
          <button
            onClick={() => goTo(-1)}
            className="absolute left-2 sm:left-4 top-1/2 -translate-y-1/2 z-20 w-9 h-9 sm:w-11 sm:h-11 rounded-full bg-black/20 backdrop-blur-sm border border-white/20 flex items-center justify-center text-white hover:bg-black/40 transition-all"
            aria-label="Previous slide"
          >
            <ChevronLeft className="h-4 w-4 sm:h-5 sm:w-5" />
          </button>
          <button
            onClick={() => goTo(1)}
            className="absolute right-2 sm:right-4 top-1/2 -translate-y-1/2 z-20 w-9 h-9 sm:w-11 sm:h-11 rounded-full bg-black/20 backdrop-blur-sm border border-white/20 flex items-center justify-center text-white hover:bg-black/40 transition-all"
            aria-label="Next slide"
          >
            <ChevronRight className="h-4 w-4 sm:h-5 sm:w-5" />
          </button>

          {/* Slide Indicators */}
          <div className="absolute bottom-4 sm:bottom-6 left-1/2 -translate-x-1/2 z-20 flex gap-1.5 sm:gap-2">
            {activeSlides.map((_: any, i: number) => (
              <button
                key={i}
                onClick={() => setCurrentSlide(i)}
                aria-label={`Go to slide ${i + 1}`}
                className={`h-1 sm:h-1.5 rounded-full transition-all duration-500 ${
                  i === currentSlide
                    ? "bg-primary w-7 sm:w-10"
                    : "bg-white/40 w-3 sm:w-4 hover:bg-white/60"
                }`}
              />
            ))}
          </div>
        </>
      )}
    </section>
  );
};

export default HeroSection;
