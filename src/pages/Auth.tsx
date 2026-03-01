import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import logo from "@/assets/logo.jpg";
import { Eye, EyeOff, Phone, Mail, Shield, CheckCircle2, XCircle } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageContext";

type AuthMode = "login" | "register" | "otp" | "forgot" | "force_password_change";

const Auth = () => {
  const navigate = useNavigate();
  const { t } = useLanguage();
  const [mode, setMode] = useState<AuthMode>("login");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmNewPassword, setConfirmNewPassword] = useState("");

  const [otpPhone, setOtpPhone] = useState("");
  const [otpCode, setOtpCode] = useState("");
  const [otpSent, setOtpSent] = useState(false);

  const [resetEmail, setResetEmail] = useState("");

  const inputClass =
    "w-full bg-secondary border border-border rounded-md px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40";

  const passwordRules = [
    { label: t("auth.passwordRules.length"), test: (p: string) => p.length >= 8 },
    { label: t("auth.passwordRules.upper"), test: (p: string) => /[A-Z]/.test(p) },
    { label: t("auth.passwordRules.lower"), test: (p: string) => /[a-z]/.test(p) },
    { label: t("auth.passwordRules.number"), test: (p: string) => /\d/.test(p) },
    { label: t("auth.passwordRules.special"), test: (p: string) => /[!@#$%^&*(),.?\":{}|<>]/.test(p) },
  ];

  const isPasswordStrong = passwordRules.every((r) => r.test(password));

  const handleEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
      if (error) throw error;

      // Check if this is an auto-created account that needs password change
      const isAutoCreated = data.user?.user_metadata?.auto_created === true;
      if (isAutoCreated) {
        setPassword("");
        setNewPassword("");
        setConfirmNewPassword("");
        setMode("force_password_change");
        setLoading(false);
        return;
      }

      const { data: roleData } = await supabase.from("user_roles").select("role").eq("user_id", data.user.id);
      const roles = (roleData || []).map((r: any) => r.role as string);
      const isAdminRole = roles.includes("admin") || roles.includes("manager") || roles.includes("staff");
      toast.success(t("auth.welcomeBackToast"));
      navigate(isAdminRole ? "/admin" : "/dashboard");
    } catch (err: any) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleForcePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPasswordRulesValid) {
      toast.error(t("auth.meetPwReq"));
      return;
    }
    if (newPassword !== confirmNewPassword) {
      toast.error("Passwords do not match");
      return;
    }
    setLoading(true);
    try {
      // Update password
      const { error: pwError } = await supabase.auth.updateUser({ password: newPassword });
      if (pwError) throw pwError;

      // Clear the auto_created flag
      const { error: metaError } = await supabase.auth.updateUser({
        data: { auto_created: false },
      });
      if (metaError) console.error("Failed to clear auto_created flag:", metaError);

      // Now navigate to dashboard
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: roleData } = await supabase.from("user_roles").select("role").eq("user_id", user.id);
        const roles = (roleData || []).map((r: any) => r.role as string);
        const isAdminRole = roles.includes("admin") || roles.includes("manager") || roles.includes("staff");
        toast.success("Password updated successfully! Welcome!");
        navigate(isAdminRole ? "/admin" : "/dashboard");
      }
    } catch (err: any) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  const newPasswordRules = [
    { label: t("auth.passwordRules.length"), test: (p: string) => p.length >= 8 },
    { label: t("auth.passwordRules.upper"), test: (p: string) => /[A-Z]/.test(p) },
    { label: t("auth.passwordRules.lower"), test: (p: string) => /[a-z]/.test(p) },
    { label: t("auth.passwordRules.number"), test: (p: string) => /\d/.test(p) },
    { label: t("auth.passwordRules.special"), test: (p: string) => /[!@#$%^&*(),.?\":{}|<>]/.test(p) },
  ];
  const newPasswordRulesValid = newPasswordRules.every((r) => r.test(newPassword));

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isPasswordStrong) {
      toast.error(t("auth.meetPwReq"));
      return;
    }
    setLoading(true);
    try {
      const { error } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          data: { full_name: fullName.trim(), phone: phone.trim() },
          emailRedirectTo: window.location.origin,
        },
      });
      if (error) throw error;
      toast.success(t("auth.accountCreated"));
      setMode("login");
    } catch (err: any) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSendOtp = async () => {
    const cleaned = otpPhone.trim().replace(/[^\d+]/g, "");
    if (cleaned.length < 10) {
      toast.error(t("auth.validPhone"));
      return;
    }
    setLoading(true);
    try {
      const res = await supabase.functions.invoke("send-otp", { body: { phone: cleaned, action: "send" } });
      if (res.error) throw new Error(res.error.message);
      if (res.data?.error) throw new Error(res.data.error);
      toast.success(t("auth.otpSentSuccess"));
      setOtpSent(true);
    } catch (err: any) {
      toast.error(err.message || "Failed to send OTP");
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async () => {
    if (otpCode.length !== 6) {
      toast.error(t("auth.enter6Digit"));
      return;
    }
    setLoading(true);
    try {
      const cleaned = otpPhone.trim().replace(/[^\d+]/g, "");
      const res = await supabase.functions.invoke("send-otp", { body: { phone: cleaned, action: "verify", code: otpCode } });
      if (res.error) throw new Error(res.error.message);
      if (res.data?.error) throw new Error(res.data.error);
      if (res.data?.access_token && res.data?.refresh_token) {
        const { error } = await supabase.auth.setSession({ access_token: res.data.access_token, refresh_token: res.data.refresh_token });
        if (error) throw error;
        toast.success(t("auth.loggedIn"));
        navigate("/dashboard");
      } else {
        toast.error(t("auth.authFailed"));
      }
    } catch (err: any) {
      toast.error(err.message || "OTP verification failed");
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(resetEmail.trim(), {
        redirectTo: `${window.location.origin}/reset-password`,
      });
      if (error) throw error;
      toast.success(t("auth.resetLinkSent"));
    } catch (err: any) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <a href="/" className="inline-flex items-center gap-3 mb-4">
            <img src={logo} alt="Logo" className="h-14 w-14 rounded-md object-cover" />
            <div className="text-left">
              <span className="font-heading text-xl font-bold text-primary">RAHE KABA</span>
              <span className="block text-xs tracking-[0.25em] text-muted-foreground uppercase">Tours & Travels</span>
            </div>
          </a>
          <h1 className="font-heading text-2xl font-bold mt-4">
            {mode === "login" && t("auth.welcomeBack")}
            {mode === "register" && t("auth.createAccount")}
            {mode === "otp" && t("auth.phoneLogin")}
            {mode === "forgot" && t("auth.resetPassword")}
            {mode === "force_password_change" && "🔐 Change Your Password"}
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            {mode === "login" && t("auth.signInDesc")}
            {mode === "register" && t("auth.registerDesc")}
            {mode === "otp" && t("auth.otpDesc")}
            {mode === "forgot" && t("auth.forgotDesc")}
            {mode === "force_password_change" && "Your account was auto-created. Please set a new password for security."}
          </p>
        </div>

        {mode === "login" && (
          <form onSubmit={handleEmailLogin} className="bg-card border border-border rounded-xl p-6 space-y-4">
            <div>
              <label className="text-sm font-medium mb-1 block">{t("auth.email")}</label>
              <div className="relative">
                <Mail className="absolute left-3 top-3.5 h-4 w-4 text-muted-foreground" />
                <input type="email" required value={email} onChange={(e) => setEmail(e.target.value)}
                  className={`${inputClass} pl-10`} placeholder={t("auth.yourEmail")} />
              </div>
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">{t("auth.password")}</label>
              <div className="relative">
                <Shield className="absolute left-3 top-3.5 h-4 w-4 text-muted-foreground" />
                <input type={showPassword ? "text" : "password"} required minLength={6} value={password}
                  onChange={(e) => setPassword(e.target.value)} className={`${inputClass} pl-10 pr-10`} placeholder={t("auth.yourPassword")} />
                <button type="button" onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-3.5 text-muted-foreground hover:text-foreground">
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>
            <div className="text-right">
              <button type="button" onClick={() => setMode("forgot")} className="text-xs text-primary hover:underline">
                {t("auth.forgotPassword")}
              </button>
            </div>
            <button type="submit" disabled={loading}
              className="w-full bg-gradient-gold text-primary-foreground font-semibold py-3 rounded-md text-sm hover:opacity-90 transition-opacity shadow-gold disabled:opacity-50">
              {loading ? t("auth.signingIn") : t("auth.signIn")}
            </button>
          </form>
        )}

        {mode === "register" && (
          <form onSubmit={handleRegister} className="bg-card border border-border rounded-xl p-6 space-y-4">
            <div>
              <label className="text-sm font-medium mb-1 block">{t("auth.fullName")}</label>
              <input type="text" required value={fullName} onChange={(e) => setFullName(e.target.value)}
                className={inputClass} placeholder={t("auth.enterFullName")} maxLength={100} />
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">{t("auth.email")}</label>
              <div className="relative">
                <Mail className="absolute left-3 top-3.5 h-4 w-4 text-muted-foreground" />
                <input type="email" required value={email} onChange={(e) => setEmail(e.target.value)}
                  className={`${inputClass} pl-10`} placeholder={t("auth.yourEmail")} maxLength={255} />
              </div>
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">{t("auth.phoneNumber")}</label>
              <div className="relative">
                <Phone className="absolute left-3 top-3.5 h-4 w-4 text-muted-foreground" />
                <input type="tel" required value={phone} onChange={(e) => setPhone(e.target.value)}
                  className={`${inputClass} pl-10`} placeholder={t("auth.phonePlaceholder")} maxLength={15} />
              </div>
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">{t("auth.password")}</label>
              <div className="relative">
                <Shield className="absolute left-3 top-3.5 h-4 w-4 text-muted-foreground" />
                <input type={showPassword ? "text" : "password"} required value={password}
                  onChange={(e) => setPassword(e.target.value)} className={`${inputClass} pl-10 pr-10`} placeholder={t("auth.createStrongPw")} />
                <button type="button" onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-3.5 text-muted-foreground hover:text-foreground">
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              {password.length > 0 && (
                <div className="mt-2 space-y-1">
                  {passwordRules.map((rule) => (
                    <div key={rule.label} className="flex items-center gap-2 text-xs">
                      {rule.test(password) ? (
                        <CheckCircle2 className="h-3.5 w-3.5 text-emerald-500" />
                      ) : (
                        <XCircle className="h-3.5 w-3.5 text-destructive" />
                      )}
                      <span className={rule.test(password) ? "text-emerald-500" : "text-muted-foreground"}>
                        {rule.label}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <button type="submit" disabled={loading || !isPasswordStrong}
              className="w-full bg-gradient-gold text-primary-foreground font-semibold py-3 rounded-md text-sm hover:opacity-90 transition-opacity shadow-gold disabled:opacity-50">
              {loading ? t("auth.creatingAccount") : t("auth.createAccountBtn")}
            </button>
          </form>
        )}

        {mode === "otp" && (
          <div className="bg-card border border-border rounded-xl p-6 space-y-4">
            {!otpSent ? (
              <>
                <div>
                  <label className="text-sm font-medium mb-1 block">{t("auth.phoneNumber")}</label>
                  <div className="relative">
                    <Phone className="absolute left-3 top-3.5 h-4 w-4 text-muted-foreground" />
                    <input type="tel" value={otpPhone} onChange={(e) => setOtpPhone(e.target.value)}
                      className={`${inputClass} pl-10`} placeholder={t("auth.phonePlaceholder")} maxLength={15} />
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">{t("auth.enterPhone")}</p>
                </div>
                <button onClick={handleSendOtp} disabled={loading}
                  className="w-full bg-gradient-gold text-primary-foreground font-semibold py-3 rounded-md text-sm hover:opacity-90 transition-opacity shadow-gold disabled:opacity-50">
                  {loading ? t("auth.sending") : t("auth.sendOtp")}
                </button>
              </>
            ) : (
              <>
                <p className="text-sm text-center text-muted-foreground">
                  {t("auth.otpSentTo")} <span className="text-primary font-medium">{otpPhone}</span>
                </p>
                <div>
                  <input type="text" inputMode="numeric" maxLength={6} value={otpCode}
                    onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ""))}
                    className={`${inputClass} text-center text-2xl tracking-[0.5em] font-mono`}
                    placeholder="000000" />
                </div>
                <button onClick={handleVerifyOtp} disabled={loading || otpCode.length !== 6}
                  className="w-full bg-gradient-gold text-primary-foreground font-semibold py-3 rounded-md text-sm hover:opacity-90 transition-opacity shadow-gold disabled:opacity-50">
                  {loading ? t("auth.verifying") : t("auth.verifyLogin")}
                </button>
                <button onClick={() => { setOtpSent(false); setOtpCode(""); }}
                  className="w-full text-sm text-muted-foreground hover:text-foreground">
                  {t("auth.resendOrChange")}
                </button>
              </>
            )}
          </div>
        )}

        {mode === "forgot" && (
          <form onSubmit={handleForgotPassword} className="bg-card border border-border rounded-xl p-6 space-y-4">
            <div>
              <label className="text-sm font-medium mb-1 block">{t("auth.emailAddress")}</label>
              <div className="relative">
                <Mail className="absolute left-3 top-3.5 h-4 w-4 text-muted-foreground" />
                <input type="email" required value={resetEmail} onChange={(e) => setResetEmail(e.target.value)}
                  className={`${inputClass} pl-10`} placeholder={t("auth.yourEmail")} />
              </div>
            </div>
            <button type="submit" disabled={loading}
              className="w-full bg-gradient-gold text-primary-foreground font-semibold py-3 rounded-md text-sm hover:opacity-90 transition-opacity shadow-gold disabled:opacity-50">
              {loading ? t("auth.sending") : t("auth.sendResetLink")}
            </button>
          </form>
        )}

        {mode === "force_password_change" && (
          <form onSubmit={handleForcePasswordChange} className="bg-card border border-border rounded-xl p-6 space-y-4">
            <div className="bg-primary/5 border border-primary/20 rounded-lg p-4 text-sm text-center">
              <Shield className="h-6 w-6 text-primary mx-auto mb-2" />
              <p className="font-medium">Security Required</p>
              <p className="text-xs text-muted-foreground mt-1">
                Your account was created automatically during a guest booking. Please set a strong password to secure your account.
              </p>
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">New Password</label>
              <div className="relative">
                <Shield className="absolute left-3 top-3.5 h-4 w-4 text-muted-foreground" />
                <input type={showPassword ? "text" : "password"} required value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)} className={`${inputClass} pl-10 pr-10`} placeholder="Enter new password" />
                <button type="button" onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-3.5 text-muted-foreground hover:text-foreground">
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              {newPassword.length > 0 && (
                <div className="mt-2 space-y-1">
                  {newPasswordRules.map((rule) => (
                    <div key={rule.label} className="flex items-center gap-2 text-xs">
                      {rule.test(newPassword) ? (
                        <CheckCircle2 className="h-3.5 w-3.5 text-emerald-500" />
                      ) : (
                        <XCircle className="h-3.5 w-3.5 text-destructive" />
                      )}
                      <span className={rule.test(newPassword) ? "text-emerald-500" : "text-muted-foreground"}>
                        {rule.label}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">Confirm New Password</label>
              <div className="relative">
                <Shield className="absolute left-3 top-3.5 h-4 w-4 text-muted-foreground" />
                <input type={showPassword ? "text" : "password"} required value={confirmNewPassword}
                  onChange={(e) => setConfirmNewPassword(e.target.value)} className={`${inputClass} pl-10`}
                  placeholder="Re-enter new password" />
              </div>
              {confirmNewPassword.length > 0 && newPassword !== confirmNewPassword && (
                <p className="text-xs text-destructive mt-1 flex items-center gap-1">
                  <XCircle className="h-3.5 w-3.5" /> Passwords do not match
                </p>
              )}
              {confirmNewPassword.length > 0 && newPassword === confirmNewPassword && newPasswordRulesValid && (
                <p className="text-xs text-emerald-500 mt-1 flex items-center gap-1">
                  <CheckCircle2 className="h-3.5 w-3.5" /> Passwords match
                </p>
              )}
            </div>
            <button type="submit" disabled={loading || !newPasswordRulesValid || newPassword !== confirmNewPassword}
              className="w-full bg-gradient-gold text-primary-foreground font-semibold py-3 rounded-md text-sm hover:opacity-90 transition-opacity shadow-gold disabled:opacity-50">
              {loading ? "Updating..." : "Set New Password & Continue"}
            </button>
          </form>
        )}

        <div className="text-center text-sm text-muted-foreground mt-4 space-y-1">
          {mode === "login" && (
            <p>{t("auth.noAccount")}{" "}
              <button onClick={() => setMode("register")} className="text-primary hover:underline font-medium">{t("auth.signUp")}</button>
            </p>
          )}
          {mode === "register" && (
            <p>{t("auth.hasAccount")}{" "}
              <button onClick={() => setMode("login")} className="text-primary hover:underline font-medium">{t("auth.signIn")}</button>
            </p>
          )}
          {(mode === "otp" || mode === "forgot") && (
            <p>
              <button onClick={() => setMode("login")} className="text-primary hover:underline font-medium">{t("auth.backToSignIn")}</button>
            </p>
          )}
        </div>
      </div>
    </div>
  );
};

export default Auth;