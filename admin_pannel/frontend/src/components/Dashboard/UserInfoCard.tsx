/**
 * User information card component
 */

import React from 'react';
import { SosEvent } from '../../types';
import { format } from 'date-fns';
import InvestigationReportViewer from '../InvestigationReportViewer';

interface UserInfoCardProps {
    event: SosEvent | null;
}

const UserInfoCard: React.FC<UserInfoCardProps> = ({ event }) => {
    const [showAnalysis, setShowAnalysis] = React.useState(false);

    if (!event || !event.user) {
        return (
            <div className="card h-full flex items-center justify-center text-gray-400">
                Select an event to view user information
            </div>
        );
    }

    const { user } = event;

    return (
        <div className="card h-full flex flex-col">
            <h3 className="font-semibold text-white mb-4">USER INFORMATION</h3>

            <div className="flex items-center mb-4">
                <div className="w-16 h-16 rounded-full bg-gradient-to-br from-danger to-warning flex items-center justify-center text-white text-2xl font-bold mr-4">
                    {user.name.charAt(0)}
                </div>
                <div>
                    <h4 className="text-white font-bold">{user.name}</h4>
                    <p className="text-gray-400 text-sm">ID: {event.userId.slice(0, 8)}...</p>
                </div>
            </div>

            <div className="space-y-2 text-sm flex-grow">
                <div className="flex justify-between">
                    <span className="text-gray-400">Registered Since:</span>
                    <span className="text-white">2023-01-15</span>
                </div>
                <div className="mt-3">
                    <span className="text-gray-400">Medical Conditions:</span>
                    <p className="text-white mt-1">{user.medicalConditions || 'None reported'}</p>
                </div>
                <div className="mt-3">
                    <span className="text-gray-400">Allergies:</span>
                    <p className="text-white mt-1">{user.allergies || 'None reported'}</p>
                </div>
            </div>

            <div className="mt-6 pt-4 border-t border-gray-700">
                <button
                    onClick={() => setShowAnalysis(true)}
                    className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white py-2 px-4 rounded-lg flex items-center justify-center gap-2 transition-all shadow-lg hover:shadow-blue-500/20"
                >
                    <span className="text-xl">🤖</span>
                    <span className="font-medium">Analyze Activity with AI</span>
                </button>
            </div>

            {/* Analysis Modal */}
            {showAnalysis && (
                <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
                    <div className="bg-navy-dark rounded-xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col border border-gray-700">
                        <div className="flex items-center justify-between p-4 border-b border-gray-700 bg-navy-light/50">
                            <h3 className="text-xl font-bold text-white flex items-center gap-2">
                                🤖 AI Activity Analysis
                            </h3>
                            <button
                                onClick={() => setShowAnalysis(false)}
                                className="text-gray-400 hover:text-white p-1 hover:bg-white/10 rounded-full transition-colors"
                            >
                                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                </svg>
                            </button>
                        </div>
                        <div className="flex-1 overflow-y-auto p-4">
                            <InvestigationReportViewer
                                touristId={event.userId}
                                tripId={event.id} // Using event ID as trip ID for now since we lack explicit trip context
                                incidentType="SOS Event"
                            />
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default UserInfoCard;
