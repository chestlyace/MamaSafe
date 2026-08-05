import LandingNav from '../components/landing/LandingNav';
import HeroSection from '../components/landing/HeroSection';
import ProblemSection from '../components/landing/ProblemSection';
import WhatItIsSection from '../components/landing/WhatItIsSection';
import HowItWorksSection from '../components/landing/HowItWorksSection';
import RiskSimulator from '../components/landing/RiskSimulator';
import FeaturesSection from '../components/landing/FeaturesSection';
import MobileAppSection from '../components/landing/MobileAppSection';
import AudienceSection from '../components/landing/AudienceSection';
import ImpactSection from '../components/landing/ImpactSection';
import CTASection from '../components/landing/CTASection';

export default function LandingPage() {
  return (
    <main className="min-h-screen bg-canvas text-text-body">
      <LandingNav />
      <HeroSection />
      <ProblemSection />
      <WhatItIsSection />
      <HowItWorksSection />
      <RiskSimulator />
      <FeaturesSection />
      <MobileAppSection />
      <AudienceSection />
      <ImpactSection />
      <CTASection />
    </main>
  );
}
