import { forwardRef, useState } from "react";
import { motion } from "framer-motion";
import { Phone, Mail, MapPin, Clock } from "lucide-react";
import { toast } from "sonner";
import { useSiteContent } from "@/hooks/useSiteContent";
import { useLanguage } from "@/i18n/LanguageContext";

const ContactSection = forwardRef<HTMLElement>(function ContactSection(_, ref) {
  const { data: content } = useSiteContent("contact");
  const { t, language } = useLanguage();
  const bn = language === "bn";
  const [form, setForm] = useState({ name: "", phone: "", email: "", service: "", message: "" });
  const [loading, setLoading] = useState(false);

  const lc = content?.[language];
  const phone = content?.phone || "+880 1711-993562";
  const email = lc?.email || content?.email || "manasiktravelhub@gmail.com";
  const location = lc?.location || (language === "bn" ? "৫৯৫/১, মিল্ক ভিটা রোড, তিন রাস্তার মোড়\nদেওলা, টাঙ্গাইল সদর, টাঙ্গাইল" : content?.location || "595/1, Milk Vita Road, Three-way Intersection\nDewla, Tangail Sadar, Tangail");
  const hours = lc?.hours || (language === "bn" ? "শনি - বৃহঃ: সকাল ৯টা - রাত ৯টা" : content?.hours || "Sat - Thu: 9AM - 9PM");

  const contactItems = [
    { icon: Phone, label: t("contact.phone"), value: phone, href: `tel:${phone.replace(/[\s-]/g, "")}` },
    { icon: Mail, label: t("contact.email"), value: email, href: `mailto:${email}` },
    { icon: MapPin, label: t("contact.location"), value: location, href: "#" },
    { icon: Clock, label: t("contact.hours"), value: hours, href: "#" },
  ];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim() || !form.phone.trim()) {
      toast.error(bn ? "প্রয়োজনীয় তথ্য পূরণ করুন" : "Please fill in required fields");
      return;
    }
    setLoading(true);
    try {
      const API_URL = import.meta.env.VITE_API_URL || '/api';
      const res = await fetch(`${API_URL}/contact`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      if (res.ok) {
        toast.success(bn ? "আপনার বার্তা সফলভাবে পাঠানো হয়েছে!" : "Your message has been sent successfully!");
        setForm({ name: "", phone: "", email: "", service: "", message: "" });
      } else {
        toast.error(bn ? "বার্তা পাঠাতে সমস্যা হয়েছে" : "Failed to send message");
      }
    } catch {
      toast.error(bn ? "বার্তা পাঠাতে সমস্যা হয়েছে" : "Failed to send message");
    }
    setLoading(false);
  };

  const inputClass = "bg-secondary border border-border rounded-md px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40";

  return (
    <section ref={ref} id="contact" className="py-24 bg-secondary/50 islamic-border-top">
      <div className="container mx-auto px-4">
        <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-16">
          <span className="text-primary text-sm font-medium tracking-[0.3em] uppercase">{lc?.section_label || t("contact.label")}</span>
          <h2 className="font-heading text-3xl md:text-5xl font-bold mt-3 mb-4">
            {lc?.heading || t("contact.heading")} <span className="text-gradient-gold">{lc?.heading_highlight || t("contact.headingHighlight")}</span>
          </h2>
        </motion.div>

        <div className="grid md:grid-cols-2 gap-12 max-w-5xl mx-auto">
          <motion.div initial={{ opacity: 0, x: -30 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} className="space-y-6">
            {contactItems.map((item) => (
              <a key={item.label} href={item.href} className="flex items-start gap-4 p-4 rounded-lg border border-border hover:border-primary/40 transition-colors group">
                <div className="w-12 h-12 rounded-md bg-primary/10 flex items-center justify-center flex-shrink-0 group-hover:bg-primary/20 transition-colors">
                  <item.icon className="h-5 w-5 text-primary" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">{item.label}</p>
                  <p className="font-medium">{item.value}</p>
                </div>
              </a>
            ))}
          </motion.div>

          <motion.form initial={{ opacity: 0, x: 30 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} className="space-y-4" onSubmit={handleSubmit}>
            <div className="grid grid-cols-2 gap-4">
              <input type="text" placeholder={t("contact.yourName")} value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} className={inputClass} required />
              <input type="tel" placeholder={t("contact.phoneNumber")} value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} className={inputClass} required />
            </div>
            <input type="email" placeholder={t("contact.emailAddress")} value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} className={`w-full ${inputClass}`} />
            <select value={form.service} onChange={(e) => setForm({ ...form, service: e.target.value })} className={`w-full ${inputClass} text-muted-foreground`}>
              <option value="">{t("contact.selectService")}</option>
              <option>{t("contact.hajjPackage")}</option>
              <option>{t("contact.umrahPackage")}</option>
              <option>{t("contact.visaProcessing")}</option>
              <option>{t("contact.airTicketService")}</option>
              <option>{t("contact.hotelBooking")}</option>
              <option>{t("contact.other")}</option>
            </select>
            <textarea rows={4} placeholder={t("contact.yourMessage")} value={form.message} onChange={(e) => setForm({ ...form, message: e.target.value })} className={`w-full ${inputClass} resize-none`} />
            <button type="submit" disabled={loading} className="w-full bg-gradient-gold text-primary-foreground font-semibold py-3 rounded-md text-sm hover:opacity-90 transition-opacity shadow-gold disabled:opacity-50">
              {loading ? (bn ? "পাঠানো হচ্ছে..." : "Sending...") : t("contact.sendMessage")}
            </button>
          </motion.form>
        </div>
      </div>
    </section>
  );
});

export default ContactSection;
