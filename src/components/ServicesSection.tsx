import { motion } from "framer-motion";
import {
  ArrowUpRight,
  Moon,
  Compass,
  Plane,
  Globe2,
  Briefcase,
  Stethoscope,
  HardHat,
  Ambulance,
  Sparkles,
} from "lucide-react";
import { useLanguage } from "@/i18n/LanguageContext";

interface Service {
  Icon: React.ComponentType<{ className?: string }>;
  badge: string;
  gradient: string; // tailwind gradient classes
  titleEn: string;
  titleBn: string;
  descEn: string;
  descBn: string;
}

const services: Service[] = [
  {
    Icon: Sparkles,
    badge: "Hajj",
    gradient: "from-emerald-500 to-teal-600",
    titleEn: "Premium Hajj Package",
    titleBn: "প্রিমিয়াম হজ্জ প্যাকেজ",
    descEn: "Expert guidance, premium hotels near Haram and full pilgrimage support.",
    descBn: "অভিজ্ঞ গাইড, হারামের কাছাকাছি প্রিমিয়াম হোটেল ও পূর্ণ সহায়তা।",
  },
  {
    Icon: Moon,
    badge: "Umrah",
    gradient: "from-teal-500 to-cyan-600",
    titleEn: "Premium Umrah Package",
    titleBn: "প্রিমিয়াম উমরাহ প্যাকেজ",
    descEn: "Year-round Umrah packages for individuals, families and groups.",
    descBn: "ব্যক্তি, পরিবার ও গ্রুপের জন্য সারাবছর উমরাহ প্যাকেজ।",
  },
  {
    Icon: Compass,
    badge: "Tour",
    gradient: "from-amber-500 to-orange-600",
    titleEn: "International Tour Package",
    titleBn: "ইন্টারন্যাশনাল ট্যুর প্যাকেজ",
    descEn: "Curated holidays to top destinations across Asia, Europe and beyond.",
    descBn: "এশিয়া, ইউরোপ ও বিশ্বের সেরা গন্তব্যে কিউরেটেড হলিডে।",
  },
  {
    Icon: Plane,
    badge: "Flights",
    gradient: "from-sky-500 to-blue-600",
    titleEn: "Air Tickets",
    titleBn: "এয়ার টিকিট",
    descEn: "Best fares on domestic & international flights with flexible booking.",
    descBn: "ডোমেস্টিক ও ইন্টারন্যাশনাল ফ্লাইটে সেরা মূল্য, সহজ বুকিং।",
  },
  {
    Icon: Globe2,
    badge: "Visa",
    gradient: "from-indigo-500 to-violet-600",
    titleEn: "Tourist Visa",
    titleBn: "ট্যুরিস্ট ভিসা",
    descEn: "Smooth tourist visa processing for popular destinations worldwide.",
    descBn: "বিশ্বের জনপ্রিয় গন্তব্যের জন্য সহজ ট্যুরিস্ট ভিসা প্রসেসিং।",
  },
  {
    Icon: Briefcase,
    badge: "Visa",
    gradient: "from-violet-500 to-purple-600",
    titleEn: "Business Visa",
    titleBn: "বিজনেস ভিসা",
    descEn: "Professional business visa support with invitation letters & docs.",
    descBn: "ইনভিটেশন লেটার ও ডকুমেন্টেশনসহ বিজনেস ভিসা সাপোর্ট।",
  },
  {
    Icon: Stethoscope,
    badge: "Visa",
    gradient: "from-rose-500 to-pink-600",
    titleEn: "Medical Visa",
    titleBn: "মেডিকেল ভিসা",
    descEn: "Medical travel arrangements with hospital appointments & care.",
    descBn: "হাসপাতাল অ্যাপয়েন্টমেন্ট ও যত্নসহ মেডিকেল ভিসা।",
  },
  {
    Icon: HardHat,
    badge: "Visa",
    gradient: "from-yellow-500 to-amber-600",
    titleEn: "Work Visa",
    titleBn: "ওয়ার্ক ভিসা",
    descEn: "End-to-end work visa processing for global job opportunities.",
    descBn: "বিদেশে কাজের সুযোগের জন্য সম্পূর্ণ ওয়ার্ক ভিসা প্রসেসিং।",
  },
  {
    Icon: Ambulance,
    badge: "Emergency",
    gradient: "from-red-500 to-rose-600",
    titleEn: "Air Ambulance",
    titleBn: "এয়ার অ্যাম্বুলেন্স",
    descEn: "Domestic & international medical evacuation, 24/7 rapid response.",
    descBn: "২৪/৭ দ্রুত সাড়া, দেশি-বিদেশি মেডিকেল ইভাকুয়েশন।",
  },
];

const ServicesSection = () => {
  const { language } = useLanguage();

  return (
    <section id="services" className="py-24 relative overflow-hidden bg-background">
      {/* Subtle decorative blobs */}
      <div className="absolute top-20 -left-32 w-80 h-80 rounded-full bg-primary/5 blur-3xl pointer-events-none" />
      <div className="absolute bottom-20 -right-32 w-80 h-80 rounded-full bg-secondary/5 blur-3xl pointer-events-none" />

      <div className="container mx-auto px-4 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center max-w-2xl mx-auto mb-14"
        >
          <span className="inline-block text-primary text-xs font-bold tracking-[0.3em] uppercase mb-3">
            {language === "bn" ? "আমাদের সার্ভিস" : "What We Offer"}
          </span>
          <h2 className="font-heading text-3xl md:text-5xl font-extrabold mb-4">
            {language === "bn" ? "সম্পূর্ণ ভ্রমণ " : "Complete travel "}
            <span className="text-gradient-sunset">
              {language === "bn" ? "সমাধান" : "solutions"}
            </span>
          </h2>
          <p className="text-muted-foreground text-base md:text-lg">
            {language === "bn"
              ? "এক জায়গায় হজ্জ, উমরাহ, ট্যুর, টিকিট, ভিসা ও জরুরি সহায়তা।"
              : "Hajj, Umrah, tours, tickets, visa and emergency support — under one roof."}
          </p>
        </motion.div>

        {/* Clean icon grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 md:gap-6">
          {services.map((s, i) => {
            const Icon = s.Icon;
            return (
              <motion.article
                key={s.titleEn}
                initial={{ opacity: 0, y: 24 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.05, duration: 0.45 }}
                whileHover={{ y: -6 }}
                className="group relative bg-card border border-border rounded-2xl p-6 md:p-7 transition-all hover:shadow-luxury hover:border-primary/30 cursor-pointer overflow-hidden"
              >
                {/* Soft gradient corner accent */}
                <div className={`absolute -top-12 -right-12 w-32 h-32 rounded-full bg-gradient-to-br ${s.gradient} opacity-10 group-hover:opacity-25 blur-2xl transition-opacity`} />

                {/* Top row: icon + arrow */}
                <div className="flex items-start justify-between mb-5 relative">
                  <div className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${s.gradient} flex items-center justify-center shadow-lg group-hover:scale-110 group-hover:rotate-3 transition-transform duration-300`}>
                    <Icon className="h-7 w-7 text-white" />
                  </div>
                  <div className="w-9 h-9 rounded-full bg-muted flex items-center justify-center text-muted-foreground group-hover:bg-primary group-hover:text-primary-foreground group-hover:rotate-45 transition-all">
                    <ArrowUpRight className="h-4 w-4" />
                  </div>
                </div>

                {/* Badge */}
                <span className={`inline-block bg-gradient-to-r ${s.gradient} bg-clip-text text-transparent text-[10px] font-bold tracking-[0.2em] uppercase mb-2`}>
                  {s.badge}
                </span>

                {/* Title */}
                <h3 className="font-heading text-lg md:text-xl font-bold text-foreground mb-2 leading-snug">
                  {language === "bn" ? s.titleBn : s.titleEn}
                </h3>

                {/* Description */}
                <p className="text-sm text-muted-foreground leading-relaxed">
                  {language === "bn" ? s.descBn : s.descEn}
                </p>

                {/* Bottom hover line */}
                <div className={`absolute bottom-0 left-0 h-1 w-0 bg-gradient-to-r ${s.gradient} group-hover:w-full transition-all duration-500`} />
              </motion.article>
            );
          })}
        </div>
      </div>
    </section>
  );
};

export default ServicesSection;
