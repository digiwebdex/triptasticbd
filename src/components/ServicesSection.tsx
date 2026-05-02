import { motion } from "framer-motion";
import { ArrowUpRight } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageContext";
import imgHajj from "@/assets/tt-hajj.jpg";
import imgUmrah from "@/assets/tt-umrah.jpg";
import imgTour from "@/assets/tt-tour.jpg";
import imgAirTicket from "@/assets/tt-airticket.jpg";
import imgTouristVisa from "@/assets/tt-tourist-visa.jpg";
import imgBusinessVisa from "@/assets/tt-business-visa.jpg";
import imgMedicalVisa from "@/assets/tt-medical-visa.jpg";
import imgWorkVisa from "@/assets/tt-work-visa.jpg";
import imgAirAmbulance from "@/assets/tt-air-ambulance.jpg";

interface Service {
  image: string;
  badge: string;
  badgeColor: string;
  titleEn: string;
  titleBn: string;
  descEn: string;
  descBn: string;
  span?: string;
}

const services: Service[] = [
  {
    image: imgHajj,
    badge: "Spiritual",
    badgeColor: "bg-emerald-500",
    titleEn: "Premium Hajj Package",
    titleBn: "প্রিমিয়াম হজ্জ প্যাকেজ",
    descEn: "Complete Hajj packages with expert guidance, premium hotels near Haram and full pilgrimage support.",
    descBn: "অভিজ্ঞ গাইড, হারামের নিকটবর্তী প্রিমিয়াম হোটেল ও সম্পূর্ণ সহায়তা সহ হজ্জ প্যাকেজ।",
    span: "lg:col-span-2 lg:row-span-2",
  },
  {
    image: imgUmrah,
    badge: "Spiritual",
    badgeColor: "bg-emerald-500",
    titleEn: "Premium Umrah Package",
    titleBn: "প্রিমিয়াম উমরাহ প্যাকেজ",
    descEn: "Year-round Umrah packages for individuals, families and groups.",
    descBn: "ব্যক্তি, পরিবার ও গ্রুপের জন্য সারাবছর উমরাহ প্যাকেজ।",
  },
  {
    image: imgTour,
    badge: "Adventure",
    badgeColor: "bg-secondary",
    titleEn: "International Tour Package",
    titleBn: "ইন্টারন্যাশনাল ট্যুর প্যাকেজ",
    descEn: "Curated holidays to top destinations across Asia, Europe and beyond.",
    descBn: "এশিয়া, ইউরোপ ও বিশ্বের সেরা গন্তব্যে কিউরেটেড হলিডে।",
  },
  {
    image: imgAirTicket,
    badge: "Flights",
    badgeColor: "bg-sky",
    titleEn: "Domestic & International Air Tickets",
    titleBn: "দেশি-বিদেশি এয়ার টিকিট",
    descEn: "Best-fare tickets across all major airlines, with flexible booking and rescheduling.",
    descBn: "সকল প্রধান এয়ারলাইন্সের সেরা মূল্যে টিকিট, সহজ বুকিং ও রিশিডিউল।",
    span: "lg:col-span-2",
  },
  {
    image: imgTouristVisa,
    badge: "Visa",
    badgeColor: "bg-primary",
    titleEn: "Tourist Visa",
    titleBn: "ট্যুরিস্ট ভিসা",
    descEn: "Smooth tourist visa processing for popular destinations worldwide.",
    descBn: "বিশ্বের জনপ্রিয় গন্তব্যের জন্য সহজ ট্যুরিস্ট ভিসা প্রসেসিং।",
  },
  {
    image: imgBusinessVisa,
    badge: "Visa",
    badgeColor: "bg-primary",
    titleEn: "Business Visa",
    titleBn: "বিজনেস ভিসা",
    descEn: "Professional business visa support with invitation letters and documentation.",
    descBn: "ইনভিটেশন লেটার ও ডকুমেন্টেশনসহ পেশাদার বিজনেস ভিসা সাপোর্ট।",
  },
  {
    image: imgMedicalVisa,
    badge: "Visa",
    badgeColor: "bg-primary",
    titleEn: "Medical Visa",
    titleBn: "মেডিকেল ভিসা",
    descEn: "Medical travel arrangements with hospital appointments and care logistics.",
    descBn: "হাসপাতাল অ্যাপয়েন্টমেন্ট ও সম্পূর্ণ যত্নসহ মেডিকেল ভিসা ব্যবস্থা।",
  },
  {
    image: imgWorkVisa,
    badge: "Visa",
    badgeColor: "bg-primary",
    titleEn: "Work Visa",
    titleBn: "ওয়ার্ক ভিসা",
    descEn: "End-to-end work visa processing for global job opportunities.",
    descBn: "বিদেশে কাজের সুযোগের জন্য সম্পূর্ণ ওয়ার্ক ভিসা প্রসেসিং।",
  },
  {
    image: imgAirAmbulance,
    badge: "Emergency",
    badgeColor: "bg-destructive",
    titleEn: "Air Ambulance Support",
    titleBn: "এয়ার অ্যাম্বুলেন্স সাপোর্ট",
    descEn: "Domestic and international medical evacuation with rapid response 24/7.",
    descBn: "২৪/৭ দ্রুত সাড়া দিয়ে দেশি-বিদেশি মেডিকেল ইভাকুয়েশন।",
    span: "lg:col-span-3",
  },
];

const ServicesSection = () => {
  const { language } = useLanguage();

  return (
    <section id="services" className="py-24 relative overflow-hidden bg-background">
      <div className="absolute inset-0 travel-pattern opacity-60 pointer-events-none" />

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

        {/* Bento grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 auto-rows-[260px] gap-5">
          {services.map((s, i) => (
            <motion.article
              key={s.titleEn}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.05, duration: 0.5 }}
              className={`group relative overflow-hidden rounded-3xl shadow-luxury cursor-pointer ${s.span || ""}`}
            >
              <img
                src={s.image}
                alt={s.titleEn}
                className="absolute inset-0 w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                loading="lazy"
              />
              {/* Always-visible bottom gradient */}
              <div className="absolute inset-0 bg-gradient-to-t from-charcoal via-charcoal/40 to-transparent" />
              {/* Hover sunset overlay */}
              <div className="absolute inset-0 bg-gradient-to-t from-primary/80 via-primary/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

              {/* Badge */}
              <div className="absolute top-4 left-4 z-10">
                <span className={`${s.badgeColor} text-white text-[10px] font-bold tracking-wider uppercase px-3 py-1 rounded-full shadow-md`}>
                  {s.badge}
                </span>
              </div>

              {/* Arrow */}
              <div className="absolute top-4 right-4 z-10 w-10 h-10 rounded-full bg-white/20 backdrop-blur-md flex items-center justify-center text-white transition-transform group-hover:rotate-45 group-hover:bg-white">
                <ArrowUpRight className="h-5 w-5 group-hover:text-primary" />
              </div>

              {/* Content */}
              <div className="absolute bottom-0 left-0 right-0 p-5 md:p-6 z-10">
                <h3 className="font-heading text-lg md:text-xl font-bold text-white leading-tight mb-2 drop-shadow-md">
                  {language === "bn" ? s.titleBn : s.titleEn}
                </h3>
                <p className="text-sm text-white/85 leading-snug line-clamp-2 max-w-md">
                  {language === "bn" ? s.descBn : s.descEn}
                </p>
              </div>
            </motion.article>
          ))}
        </div>
      </div>
    </section>
  );
};

export default ServicesSection;
