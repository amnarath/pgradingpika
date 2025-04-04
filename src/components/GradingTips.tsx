import React from 'react';
import { Lightbulb, Package, Shield, Clock, DollarSign } from 'lucide-react';

export default function GradingTips() {
  const tips = [
    {
      icon: <Package className="h-6 w-6 text-indigo-600" />,
      title: "Proper Card Packaging",
      description: "Cards should be double-sleeved and placed in a semi-rigid holder. Use bubble wrap and a sturdy box for shipping. Avoid using excessive tape that might damage the cards.",
      details: [
        "Use penny sleeves as the inner sleeve",
        "Perfect fit sleeves work great as outer sleeves",
        "Place cards in Card Saver 1 or similar semi-rigid holders",
        "Avoid using screwdown cases or magnetic holders"
      ]
    },
    {
      icon: <Shield className="h-6 w-6 text-indigo-600" />,
      title: "Card Protection",
      description: "Keep your cards in a clean, temperature-controlled environment before submission. Handle cards by their edges only and avoid touching the surface.",
      details: [
        "Store cards at room temperature (65-72°F)",
        "Keep humidity between 45-50%",
        "Use clean, lint-free gloves when handling",
        "Never clean or attempt to repair cards"
      ]
    },
    {
      icon: <Clock className="h-6 w-6 text-indigo-600" />,
      title: "Timing Considerations",
      description: "Plan your submissions carefully. Consider market timing and upcoming releases that might affect card values.",
      details: [
        "Submit before major tournament seasons",
        "Watch for upcoming set releases",
        "Consider holiday season timing",
        "Allow extra time for international shipping"
      ]
    },
    {
      icon: <DollarSign className="h-6 w-6 text-indigo-600" />,
      title: "Value Maximization",
      description: "Focus on cards that will benefit most from grading. Consider market demand and potential return on investment.",
      details: [
        "Research recent sales of graded cards",
        "Focus on cards in excellent condition",
        "Consider rarity and edition",
        "Watch market trends"
      ]
    }
  ];

  return (
    <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      {/* Header Section */}
      <div className="bg-white shadow sm:rounded-lg mb-6">
        <div className="px-4 py-5 sm:p-6">
          <div className="flex items-center">
            <Lightbulb className="h-8 w-8 text-indigo-600 mr-3" />
            <h2 className="text-2xl font-bold text-gray-900">
              Grading Tips & Best Practices
            </h2>
          </div>
          <p className="mt-2 text-gray-600">
            Follow these guidelines to ensure the best possible outcome for your card grading submission.
          </p>
        </div>
      </div>

      {/* Tips Grid */}
      <div className="grid gap-6 md:grid-cols-2">
        {tips.map((tip, index) => (
          <div key={index} className="bg-white shadow sm:rounded-lg overflow-hidden">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center mb-4">
                {tip.icon}
                <h3 className="ml-3 text-lg font-medium text-gray-900">
                  {tip.title}
                </h3>
              </div>
              <p className="text-gray-600 mb-4">
                {tip.description}
              </p>
              <ul className="space-y-2">
                {tip.details.map((detail, detailIndex) => (
                  <li key={detailIndex} className="flex items-center text-gray-600">
                    <span className="h-1.5 w-1.5 bg-indigo-600 rounded-full mr-2"></span>
                    {detail}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        ))}
      </div>

      {/* Additional Resources */}
      <div className="mt-6 bg-white shadow sm:rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">
            Additional Resources
          </h3>
          <div className="prose prose-indigo">
            <ul className="space-y-2 text-gray-600">
              <li>Download our complete grading guide (Coming Soon)</li>
              <li>Watch our video tutorials on card preparation (Coming Soon)</li>
              <li>Join our community forum for more tips (Coming Soon)</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}