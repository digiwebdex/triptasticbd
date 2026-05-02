import { motion } from "framer-motion";
import { ArrowRight, Plane, Sparkles } from "lucide-react";
import heroImg from "@/assets/tt-hero.jpg";
import { useLanguage } from "@/i18n/LanguageContext";
import { useNavigate } from "react-router-dom";

const HeroSection = () => {
  const { t, language } = useLanguage();
  const navigate = useNavigate();

  const headline = language === "bn"
    ? "অসাধারণ গন্তব্যে আপনার পরবর্তী যাত্রা"
    : "Your next unforgettable journey starts here";
  const sub = language === "bn"
    ? "হজ্জ, উমরাহ, ট্যুর প্যাকেজ, এয়ার টিকিট, ভিসা প্রসেসিং এবং এয়ার অ্যাম্বুলেন্স সাপোর্ট — এক জায়গায় সম্পূর্ণ ভ্রমণ সমাধান।"
    : "Hajj, Umrah, international tours, air tickets, visa processing and air ambulance — all your travel needs in one trusted place.";

  return (
    <section
      id="hero"
      className="relative w-full min-h-[100vh] flex items-center overflow-hidden pt-20"
    >
      {/* Background photo */}
      <img
        src={heroImg}
        alt="TRIP TASTIC — airplane wing over tropical islands at sunset"
        className="absolute inset-0 w-full h-full object-cover"
        loading="eager"
        fetchPriority="high"
        decoding="async"
      />

      {/* Gradient overlays for text legibility */}
      <div className="absolute inset-0 bg-gradient-hero-overlay" />
      <div className="absolute inset-0 bg-gradient-to-r from-charcoal/70 via-charcoal/30 to-transparent" />

      {/* Floating sunset glow */}
      <div className="absolute -top-40 -right-40 w-[600px] h-[600px] rounded-full bg-primary/30 blur-3xl pointer-events-none" />
      <div className="absolute -bottom-40 -left-40 w-[500px] h-[500px] rounded-full bg-secondary/40 blur-3xl pointer-events-none" />

      <div className="container mx-auto px-4 relative z-10 py-20">
        <div className="max-w-3xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="inline-flex items-center gap-2 bg-white/10 backdrop-blur-md border border-white/20 rounded-full px-4 py-2 mb-6"
          >
            <Sparkles className="h-4 w-4 text-primary-glow" />
            <span className="text-white text-xs sm:text-sm font-medium tracking-wide">
              {language === "bn" ? "বিশ্বস্ত ট্রাভেল পার্টনার" : "Trusted travel partner"}
            </span>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.1 }}
            className="font-heading text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-extrabold text-white leading-[1.05] mb-6"
          >
            {headline.split(" ").slice(0, -2).join(" ")}{" "}
            <span className="text-gradient-sunset">
              {headline.split(" ").slice(-2).join(" ")}
            </span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.2 }}
            className="text-base sm:text-lg md:text-xl text-white/85 max-w-2xl leading-relaxed mb-10"
          >
            {sub}
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.3 }}
            className="flex flex-wrap items-center gap-4"
          >
            <button
              onClick={() => document.getElementById("services")?.scrollIntoView({ behavior: "smooth" })}
              className="group inline-flex items-center gap-2 bg-gradient-sunset text-white font-semibold px-7 py-4 rounded-full shadow-gold hover:shadow-glow transition-all hover:scale-105"
            >
              {language === "bn" ? "সার্ভিস দেখুন" : "Explore Services"}
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
            transition={{ duration: 0.7, delay: 0.5 }}
            className="mt-14 grid grid-cols-3 gap-6 sm:gap-10 max-w-xl"
          >
            {[
              { n: "10+", l: language === "bn" ? "সার্ভিস" : "Services" },
              { n: "50+", l: language === "bn" ? "গন্তব্য" : "Destinations" },
              { n: "24/7", l: language === "bn" ? "সাপোর্ট" : "Support" },
            ].map((s) => (
              <div key={s.l}>
                <div className="text-2xl sm:text-3xl font-extrabold text-white tabular-nums">{s.n}</div>
                <div className="text-xs sm:text-sm text-white/70 mt-1">{s.l}</div>
              </div>
            ))}
          </motion.div>
        </div>
      </div>

      {/* Bottom fade for next section */}
      <div className="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-b from-transparent to-background pointer-events-none" />
    </section>
  );
};

export default HeroSection;
