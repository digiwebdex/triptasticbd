import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ArrowRight, Plane, Sparkles, ChevronLeft, ChevronRight } from "lucide-react";
import heroHajj from "@/assets/hero-hajj.jpg";
import heroTickets from "@/assets/hero-tickets.jpg";
import heroTours from "@/assets/hero-tours.jpg";
import heroVisa from "@/assets/hero-visa.jpg";
import heroEmergency from "@/assets/hero-emergency.jpg";
import { useLanguage } from "@/i18n/LanguageContext";
import { useNavigate } from "react-router-dom";

const HeroSection = () => {
  const { language } = useLanguage();
  const navigate = useNavigate();
  const [index, setIndex] = useState(0);

  const slides = [
    {
      img: heroHajj,
      alt: "Kaaba in Masjid al-Haram during Hajj",
      tag: language === "bn" ? "হজ্জ ও উমরাহ প্যাকেজ" : "Hajj & Umrah Packages",
      titleStart: language === "bn" ? "পবিত্র যাত্রায়" : "Begin your sacred",
      titleAccent: language === "bn" ? "আপনার সঙ্গী" : "journey with us",
      sub: language === "bn"
        ? "অভিজ্ঞ মোয়াল্লেম, সেরা হোটেল, পূর্ণাঙ্গ গাইডেন্স — মক্কা ও মদিনায় শান্তিময় ইবাদতের নিশ্চয়তা।"
        : "Experienced moallems, premium hotels in Makkah & Madinah, complete guidance — a peaceful spiritual journey.",
      ctaPrimary: language === "bn" ? "প্যাকেজ দেখুন" : "View Packages",
      ctaPrimaryAction: () => navigate("/packages?type=hajj"),
    },
    {
      img: heroTickets,
      alt: "Airliner taking off at sunset",
      tag: language === "bn" ? "এয়ার টিকিট ও ভিসা" : "Air Tickets & Visa",
      titleStart: language === "bn" ? "সেরা দামে" : "Best fares for",
      titleAccent: language === "bn" ? "আকাশপথে যাত্রা" : "every destination",
      sub: language === "bn"
        ? "ডোমেস্টিক ও ইন্টারন্যাশনাল ফ্লাইট, কর্পোরেট গ্রুপ বুকিং এবং দ্রুত ভিসা প্রসেসিং — ২৪/৭ সাপোর্ট।"
        : "Domestic & international flights, corporate group bookings and fast visa processing — 24/7 expert support.",
      ctaPrimary: language === "bn" ? "টিকিট বুক করুন" : "Book Tickets",
      ctaPrimaryAction: () => navigate("/packages?type=air_ticket"),
    },
    {
      img: heroTours,
      alt: "Dubai Burj Khalifa with hot air balloons and tropical resorts",
      tag: language === "bn" ? "ট্যুর প্যাকেজ" : "International Tour Packages",
      titleStart: language === "bn" ? "অসাধারণ গন্তব্যে" : "Explore the world",
      titleAccent: language === "bn" ? "অবিস্মরণীয় অভিজ্ঞতা" : "in unforgettable style",
      sub: language === "bn"
        ? "দুবাই, তুরস্ক, মালয়েশিয়া, সিঙ্গাপুর, মালদ্বীপ — কাস্টমাইজড ট্যুর, লাক্সারি হোটেল ও সম্পূর্ণ ইটিনারারি।"
        : "Dubai, Turkey, Malaysia, Singapore, Maldives — customised tours with luxury stays and full itineraries.",
      ctaPrimary: language === "bn" ? "ট্যুর দেখুন" : "Explore Tours",
      ctaPrimaryAction: () => navigate("/packages?type=tour"),
    },
    {
      img: heroVisa,
      alt: "Passport, visa stamps and world map",
      tag: language === "bn" ? "ভিসা প্রসেসিং" : "Visa Processing",
      titleStart: language === "bn" ? "দ্রুত ও নির্ভরযোগ্য" : "Fast & reliable",
      titleAccent: language === "bn" ? "ভিসা সাপোর্ট" : "visa support",
      sub: language === "bn"
        ? "ট্যুরিস্ট, বিজনেস, মেডিকেল ও ওয়ার্ক ভিসা — ডকুমেন্টেশন থেকে ইন্টারভিউ পর্যন্ত পূর্ণাঙ্গ সহায়তা।"
        : "Tourist, business, medical & work visa — full assistance from documentation to interview.",
      ctaPrimary: language === "bn" ? "ভিসা সাপোর্ট" : "Get Visa Support",
      ctaPrimaryAction: () => navigate("/packages?type=visa"),
    },
    {
      img: heroEmergency,
      alt: "Air ambulance helicopter on hospital helipad",
      tag: language === "bn" ? "এয়ার অ্যাম্বুলেন্স" : "Air Ambulance",
      titleStart: language === "bn" ? "জরুরি মুহূর্তে" : "Critical care",
      titleAccent: language === "bn" ? "সবসময় পাশে" : "anytime, anywhere",
      sub: language === "bn"
        ? "২৪/৭ দেশি-বিদেশি মেডিকেল ইভাকুয়েশন, ICU-সজ্জিত এয়ারক্রাফট ও ডাক্তার-নার্স এসকর্ট।"
        : "24/7 domestic & international medical evacuation with ICU-equipped aircraft and doctor escort.",
      ctaPrimary: language === "bn" ? "এখনই কল করুন" : "Call Emergency",
      ctaPrimaryAction: () => navigate("/packages?type=emergency"),
    },
  ];

  // Auto rotate
  useEffect(() => {
    const id = setInterval(() => {
      setIndex((i) => (i + 1) % slides.length);
    }, 6000);
    return () => clearInterval(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [slides.length]);

  const current = slides[index];
  const goTo = (i: number) => setIndex((i + slides.length) % slides.length);

  return (
    <section
      id="hero"
      className="relative w-full min-h-[100vh] flex items-center overflow-hidden pt-20"
    >
      {/* Background slides */}
      <AnimatePresence mode="sync">
        <motion.img
          key={current.img}
          src={current.img}
          alt={current.alt}
          className="absolute inset-0 w-full h-full object-cover"
          loading="eager"
          fetchPriority="high"
          decoding="async"
          initial={{ opacity: 0, scale: 1.08 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0 }}
          transition={{ opacity: { duration: 1.1 }, scale: { duration: 7, ease: "linear" } }}
        />
      </AnimatePresence>

      {/* Gradient overlays for text legibility */}
      <div className="absolute inset-0 bg-gradient-hero-overlay" />
      <div className="absolute inset-0 bg-gradient-to-r from-charcoal/75 via-charcoal/40 to-transparent" />

      {/* Floating glows */}
      <div className="absolute -top-40 -right-40 w-[600px] h-[600px] rounded-full bg-primary/30 blur-3xl pointer-events-none" />
      <div className="absolute -bottom-40 -left-40 w-[500px] h-[500px] rounded-full bg-secondary/40 blur-3xl pointer-events-none" />

      <div className="container mx-auto px-4 relative z-10 py-20">
        <div className="max-w-3xl">
          <AnimatePresence mode="wait">
            <motion.div
              key={`tag-${index}`}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.5 }}
              className="inline-flex items-center gap-2 bg-white/10 backdrop-blur-md border border-white/25 rounded-full px-4 py-2 mb-6"
            >
              <Sparkles className="h-4 w-4 text-primary-glow" />
              <span className="text-white text-xs sm:text-sm font-semibold tracking-wide">
                {current.tag}
              </span>
            </motion.div>
          </AnimatePresence>

          <AnimatePresence mode="wait">
            <motion.h1
              key={`title-${index}`}
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -15 }}
              transition={{ duration: 0.6 }}
              className="font-heading text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-extrabold text-white leading-[1.05] mb-6"
            >
              {current.titleStart}{" "}
              <span className="text-gradient-sunset">{current.titleAccent}</span>
            </motion.h1>
          </AnimatePresence>

          <AnimatePresence mode="wait">
            <motion.p
              key={`sub-${index}`}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.55, delay: 0.05 }}
              className="text-base sm:text-lg md:text-xl text-white/90 max-w-2xl leading-relaxed mb-10"
            >
              {current.sub}
            </motion.p>
          </AnimatePresence>

          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.2 }}
            className="flex flex-wrap items-center gap-4"
          >
            <button
              onClick={current.ctaPrimaryAction}
              className="group inline-flex items-center gap-2 bg-gradient-sunset text-white font-semibold px-7 py-4 rounded-full shadow-gold hover:shadow-glow transition-all hover:scale-105"
            >
              {current.ctaPrimary}
              <ArrowRight className="h-4 w-4 group-hover:translate-x-1 transition-transform" />
            </button>
            <button
              onClick={() => document.getElementById("contact")?.scrollIntoView({ behavior: "smooth" })}
              className="inline-flex items-center gap-2 bg-white/10 backdrop-blur-md border border-white/30 text-white font-semibold px-7 py-4 rounded-full hover:bg-white/20 transition-all"
            >
              <Plane className="h-4 w-4" />
              {language === "bn" ? "যোগাযোগ" : "Contact Us"}
            </button>
          </motion.div>

          {/* Stats strip */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.4 }}
            className="mt-14 grid grid-cols-3 gap-6 sm:gap-10 max-w-xl"
          >
            {[
              { n: "10+", l: language === "bn" ? "সার্ভিস" : "Services" },
              { n: "50+", l: language === "bn" ? "গন্তব্য" : "Destinations" },
              { n: "24/7", l: language === "bn" ? "সাপোর্ট" : "Support" },
            ].map((s) => (
              <div key={s.l}>
                <div className="text-2xl sm:text-3xl font-extrabold text-white tabular-nums">{s.n}</div>
                <div className="text-xs sm:text-sm text-white/75 mt-1">{s.l}</div>
              </div>
            ))}
          </motion.div>
        </div>
      </div>

      {/* Slider controls */}
      <div className="absolute bottom-28 md:bottom-10 left-1/2 -translate-x-1/2 md:left-auto md:right-10 md:translate-x-0 z-20 flex items-center gap-3">
        <button
          onClick={() => goTo(index - 1)}
          aria-label="Previous slide"
          className="w-10 h-10 rounded-full bg-white/10 backdrop-blur-md border border-white/30 text-white flex items-center justify-center hover:bg-white/20 transition"
        >
          <ChevronLeft className="h-5 w-5" />
        </button>
        <div className="flex items-center gap-2">
          {slides.map((_, i) => (
            <button
              key={i}
              onClick={() => goTo(i)}
              aria-label={`Go to slide ${i + 1}`}
              className={`h-2 rounded-full transition-all ${
                i === index ? "w-8 bg-gradient-sunset" : "w-2 bg-white/40 hover:bg-white/70"
              }`}
            />
          ))}
        </div>
        <button
          onClick={() => goTo(index + 1)}
          aria-label="Next slide"
          className="w-10 h-10 rounded-full bg-white/10 backdrop-blur-md border border-white/30 text-white flex items-center justify-center hover:bg-white/20 transition"
        >
          <ChevronRight className="h-5 w-5" />
        </button>
      </div>

      {/* Bottom fade for next section */}
      <div className="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-b from-transparent to-background pointer-events-none" />
    </section>
  );
};

export default HeroSection;
