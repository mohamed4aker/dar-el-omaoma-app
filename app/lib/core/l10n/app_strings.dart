import 'package:flutter/widgets.dart';

/// Application strings.
///
/// Arabic (ar-EG) is the default language; English is a fully supported
/// secondary language (PROMPT.md section 12.1). Every field is a required
/// named parameter, so a missing translation is a compile error rather than a
/// runtime fallback to the wrong language.
///
/// This is a hand-written implementation rather than generated ARB output so
/// that the project builds with no code-generation step. Migrating to ARB and
/// `flutter gen-l10n` later requires no change to call sites.
@immutable
class AppStrings {
  const AppStrings({
    required this.localeName,
    required this.appName,
    required this.tagline,
    required this.brandLine,
    required this.commonNext,
    required this.commonBack,
    required this.commonCancel,
    required this.commonConfirm,
    required this.commonSave,
    required this.commonClose,
    required this.commonSearch,
    required this.commonRetry,
    required this.commonAll,
    required this.commonFrom,
    required this.commonTo,
    required this.commonOptional,
    required this.commonRequired,
    required this.commonEgp,
    required this.commonMinutes,
    required this.commonNoResults,
    required this.commonComingSoon,
    required this.commonSomethingWentWrong,
    required this.welcomeLogin,
    required this.welcomeRegister,
    required this.welcomeGuest,
    required this.loginTitle,
    required this.loginSubtitle,
    required this.loginPhoneLabel,
    required this.loginPhoneHint,
    required this.loginSendOtp,
    required this.loginDemoHint,
    required this.otpTitle,
    required this.otpSubtitle,
    required this.otpVerify,
    required this.otpResend,
    required this.otpInvalid,
    required this.registerTitle,
    required this.registerSubtitle,
    required this.registerFullName,
    required this.registerNationalId,
    required this.registerPhone,
    required this.registerEmail,
    required this.registerCompany,
    required this.registerCompanyHelper,
    required this.registerDerivedTitle,
    required this.registerDob,
    required this.registerGender,
    required this.registerGovernorate,
    required this.registerAcceptTerms,
    required this.registerAcceptMarketing,
    required this.registerSubmit,
    required this.errorNameFourParts,
    required this.errorNationalIdLength,
    required this.errorNationalIdInvalid,
    required this.errorPhoneInvalid,
    required this.errorEmailInvalid,
    required this.errorMustAcceptTerms,
    required this.genderMale,
    required this.genderFemale,
    required this.tabHome,
    required this.tabServices,
    required this.tabFile,
    required this.tabBookings,
    required this.tabMore,
    required this.tabPractice,
    required this.homeGreeting,
    required this.homeMrn,
    required this.homeNextAppointment,
    required this.homeResultsReady,
    required this.homeQuickServices,
    required this.homeCare,
    required this.homeComplaints,
    required this.homeTips,
    required this.homeOffers,
    required this.emergencyCall,
    required this.emergencyTitle,
    required this.servicesTitle,
    required this.serviceClinics,
    required this.serviceRadiology,
    required this.serviceLab,
    required this.serviceBloodBank,
    required this.serviceSurgery,
    required this.serviceCentres,
    required this.serviceVisitingExperts,
    required this.clinicsTitle,
    required this.clinicsChoose,
    required this.clinicConsultationFee,
    required this.clinicFollowUpFee,
    required this.clinicBookNow,
    required this.clinicChooseDoctor,
    required this.clinicFirstAvailable,
    required this.clinicChooseSlot,
    required this.clinicNoSlots,
    required this.bookingConfirmedTitle,
    required this.bookingConfirmedBody,
    required this.bookingPayAtReception,
    required this.bookingAddToCalendar,
    required this.radiologyTitle,
    required this.radiologyChooseType,
    required this.radiologyPrices,
    required this.radiologySchedules,
    required this.radiologyPreparation,
    required this.radiologyAcknowledgePrep,
    required this.labTitle,
    required this.labPrices,
    required this.labResults,
    required this.labOffers,
    required this.labTurnaround,
    required this.labSample,
    required this.bloodBankTitle,
    required this.bloodBankRequest,
    required this.bloodBankDonate,
    required this.fileTitle,
    required this.fileVitals,
    required this.fileVisits,
    required this.fileResults,
    required this.fileDocuments,
    required this.fileBloodGroup,
    required this.fileAllergies,
    required this.fileChronic,
    required this.fileMaternity,
    required this.fileGestationalAge,
    required this.fileEdd,
    required this.fileExport,
    required this.resultReady,
    required this.resultPending,
    required this.resultWithheld,
    required this.resultWithheldBody,
    required this.surgeryTitle,
    required this.surgeryCatalogue,
    required this.surgeryMyRequests,
    required this.surgeryRequestNew,
    required this.surgeryClassification,
    required this.surgeryEstimate,
    required this.surgeryEstimateNote,
    required this.surgeryPreferredSurgeon,
    required this.surgeryPreferredDates,
    required this.surgeryRequestAck,
    required this.surgeryRequestSubmitted,
    required this.surgeryRequestSubmittedBody,
    required this.surgeryNoRequests,
    required this.surgeryDuration,
    required this.statusSubmitted,
    required this.statusUnderReview,
    required this.statusApproved,
    required this.statusScheduled,
    required this.statusRejected,
    required this.statusMoreInfo,
    required this.statusCancelled,
    required this.statusCompleted,
    required this.theatreTitle,
    required this.theatreAvailability,
    required this.theatreBookDirect,
    required this.theatreFree,
    required this.theatreBooked,
    required this.theatreProvisional,
    required this.theatreTurnover,
    required this.theatreBlocked,
    required this.theatreFreeHours,
    required this.theatreToday,
    required this.theatreSelectProcedure,
    required this.theatreSelectPatient,
    required this.theatreConfirmBooking,
    required this.theatreBookedOk,
    required this.theatreConflictTheatre,
    required this.theatreConflictSurgeon,
    required this.theatreConflictPatient,
    required this.theatreConflictEquipment,
    required this.theatreConflictBlocked,
    required this.theatreWarnTheatreType,
    required this.theatreWarnSeniority,
    required this.theatreWarnOutsideHours,
    required this.theatreOverride,
    required this.theatreOverrideReason,
    required this.theatreNoApprovalNeeded,
    required this.centresTitle,
    required this.centreSpecialties,
    required this.centreProcedures,
    required this.centreClinics,
    required this.visitingTitle,
    required this.visitingExpert,
    required this.visitingHost,
    required this.visitingWindow,
    required this.visitingRegisterInterest,
    required this.visitingBookScreening,
    required this.visitingInterestDone,
    required this.visitingSeats,
    required this.visitingStageInterest,
    required this.visitingStageScreening,
    required this.visitingStageShortlisted,
    required this.visitingStageScheduled,
    required this.visitingStageWaitlisted,
    required this.homeCareTitle,
    required this.homeCareRequest,
    required this.homeCareCoverage,
    required this.complaintsTitle,
    required this.complaintsNew,
    required this.complaintsCategory,
    required this.complaintsBody,
    required this.complaintsAnonymous,
    required this.complaintsAnonymousNote,
    required this.complaintsSubmit,
    required this.complaintsReference,
    required this.complaintsSla,
    required this.offersTitle,
    required this.offersEvents,
    required this.offersValidUntil,
    required this.offersBefore,
    required this.offersAfter,
    required this.tipsTitle,
    required this.tipsDisclaimer,
    required this.tipsReviewedBy,
    required this.contactTitle,
    required this.contactCall,
    required this.contactWhatsapp,
    required this.contactAmbulance,
    required this.contactAmbulanceNote,
    required this.contactDirections,
    required this.moreTitle,
    required this.moreLanguage,
    required this.moreAppearance,
    required this.moreNotifications,
    required this.morePrivacy,
    required this.moreAbout,
    required this.moreSignOut,
    required this.moreSignIn,
    required this.aboutDevelopedBy,
    required this.aboutVisitWebsite,
    required this.aboutSupport,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.guestBannerTitle,
    required this.guestBannerBody,
    required this.guestBannerAction,
    required this.approvalsTitle,
    required this.approvalsPending,
    required this.approvalsDecided,
    required this.approvalsEmpty,
    required this.approvalsApprove,
    required this.approvalsReject,
    required this.approvalsMoreInfo,
    required this.approvalsRejectReason,
    required this.approvalsDueIn,
    required this.approvalsOverdue,
    required this.approvalsRunEscalation,
    required this.approvalsEscalated,
    required this.approvalsApprovedNote,
    required this.approvalsMoreInfoNote,
    required this.notificationsEmpty,
    required this.notificationsNoPhi,
    required this.channelPush,
    required this.channelWhatsapp,
    required this.channelSms,
    required this.channelInApp,
    required this.channelTemplateApproved,
    required this.homeCareAddress,
    required this.homeCareWindow,
    required this.homeCareNotes,
    required this.homeCareSubmitted,
    required this.homeCareMyRequests,
    required this.homeCareFreeCancel,
    required this.bloodGroup,
    required this.bloodComponent,
    required this.bloodUnits,
    required this.bloodRequiredBy,
    required this.bloodSubmitted,
    required this.bloodLastDonation,
    required this.bloodNextEligible,
    required this.bloodEligibleNow,
    required this.bloodAcceptAppeals,
    required this.bloodRegistered,
    required this.visitingPipeline,
    required this.visitingAddPatient,
    required this.visitingAddedByDoctor,
    required this.visitingSelfRegistered,
    required this.visitingCohortLive,
    required this.visitingScreeningBooked,
    required this.visitingAdvance,
    required this.bookingsTitle,
    required this.bookingsEmpty,
    required this.bookingsUpcoming,
    required this.bookingsPast,
    required this.adminConsole,
    required this.adminHomeNote,
    required this.adminAdd,
    required this.adminName,
    required this.adminTitle,
    required this.adminCode,
    required this.adminDescription,
    required this.adminCategory,
    required this.adminPrice,
    required this.adminPriceFrom,
    required this.adminPriceTo,
    required this.adminColour,
    required this.adminInactive,
    required this.adminDelete,
    required this.adminDeleteConfirm,
    required this.adminEnglishFallback,
    required this.adminNoReleaseNeeded,
    required this.adminClassifications,
    required this.adminClassificationsNote,
    required this.adminNewClassification,
    required this.adminEditClassification,
    required this.adminSchedulingDefaults,
    required this.adminDefaultsNote,
    required this.adminAnaesthesia,
    required this.adminRequiredSeniority,
    required this.adminSeniorityNote,
    required this.adminBloodUnits,
    required this.adminBloodNote,
    required this.adminSeniority,
    required this.adminProcedures,
    required this.adminNewProcedure,
    required this.adminEditProcedure,
    required this.adminTheatreType,
    required this.adminCentre,
    required this.adminNoCentre,
    required this.adminPatientRequestable,
    required this.adminPatientRequestableNote,
    required this.adminClinics,
    required this.adminNewClinic,
    required this.adminEditClinic,
    required this.adminWorkingDays,
    required this.adminDoctors,
    required this.adminDoctorsCount,
    required this.adminAddDoctorFirst,
    required this.adminNewDoctor,
    required this.adminEditDoctor,
    required this.adminDoctorTitle,
    required this.adminSpecialty,
    required this.adminTheatres,
    required this.adminNewTheatre,
    required this.adminEditTheatre,
    required this.adminOperatingHours,
    required this.adminHoursInvalid,
    required this.adminTheatreActive,
    required this.adminTheatreActiveNote,
    required this.adminOffers,
    required this.adminNewOffer,
    required this.adminEditOffer,
    required this.adminIsEvent,
    required this.adminIsEventNote,
    required this.adminTips,
    required this.adminNewTip,
    required this.adminEditTip,
    required this.adminTipBody,
    required this.adminReviewerName,
    required this.adminReviewerRequired,
    required this.doctorRequestTitle,
    required this.doctorRequestNew,
    required this.doctorRequestNote,
    required this.doctorRequestNoteLabel,
    required this.doctorRequestNoteHelp,
    required this.doctorRequestSend,
    required this.doctorRequestSent,
    required this.doctorRequestSentBody,
    required this.scheduleTitle,
    required this.scheduleRequestedBy,
    required this.scheduleDate,
    required this.scheduleTime,
    required this.scheduleConfirmedPrice,
    required this.scheduleConfirmedPriceHelp,
    required this.scheduleConfirm,
    required this.scheduleNotifiesDoctor,
    required this.scheduleDone,
    required this.scheduleAction,
    required this.scheduleQueue,
    required this.requestFromDoctor,
    required this.requestFromPatient,
    required this.adminPolicy,
    required this.policyDirectBooking,
    required this.policyDirectBookingOn,
    required this.policyDirectBookingOff,
    required this.policyNotifyOnChange,
    required this.policyNotifyOnChangeNote,
    required this.policyNotifyOffWarning,
    required this.policyApprovalWindow,
    required this.policyApprovalWindowNote,
    required this.policyCancellationCutoff,
    required this.policyCancellationNote,
    required this.policyDefaultPayment,
    required this.adminUsers,
    required this.adminNewUser,
    required this.adminEditUser,
    required this.adminRoles,
    required this.adminRolesNote,
    required this.adminApprovalCoverageThin,
    required this.adminLinkedDoctor,
    required this.adminLinkedDoctorNote,
    required this.adminAudit,
    required this.adminAuditEmpty,
    required this.adminAuditNote,
    required this.permManageCatalogue,
    required this.permManageUsers,
    required this.permApprove,
    required this.permSchedule,
    required this.permBookDirect,
    required this.permOverride,
    required this.permAudit,
    required this.adminShifts,
    required this.adminShiftsNote,
    required this.adminShiftFrom,
    required this.adminShiftTo,
    required this.adminMaxPatients,
    required this.adminNoCap,
    required this.adminWeeklyCapacity,
    required this.adminSlotLength,
    required this.adminNoShift,
    required this.adminPaymentPolicy,
    required this.adminDepositAmount,
    required this.adminAffectedBookings,
    required this.adminAffectedWarning,
    required this.adminSaveAnyway,
    required this.bookingPayNow,
    required this.bookingPayLater,
    required this.bookingDepositNote,
    required this.bookingDepositPaid,
    required this.bookingBalanceDue,
    required this.bookingFreeNote,
    required this.bookingCancelled,
    required this.bookingRebook,
    required this.capacityFull,
    required this.capacityRemaining,
  });

  final String localeName;
  final String appName;
  final String tagline;
  final String brandLine;

  final String commonNext;
  final String commonBack;
  final String commonCancel;
  final String commonConfirm;
  final String commonSave;
  final String commonClose;
  final String commonSearch;
  final String commonRetry;
  final String commonAll;
  final String commonFrom;
  final String commonTo;
  final String commonOptional;
  final String commonRequired;
  final String commonEgp;
  final String commonMinutes;
  final String commonNoResults;
  final String commonComingSoon;
  final String commonSomethingWentWrong;

  final String welcomeLogin;
  final String welcomeRegister;
  final String welcomeGuest;

  final String loginTitle;
  final String loginSubtitle;
  final String loginPhoneLabel;
  final String loginPhoneHint;
  final String loginSendOtp;
  final String loginDemoHint;

  final String otpTitle;
  final String otpSubtitle;
  final String otpVerify;
  final String otpResend;
  final String otpInvalid;

  final String registerTitle;
  final String registerSubtitle;
  final String registerFullName;
  final String registerNationalId;
  final String registerPhone;
  final String registerEmail;
  final String registerCompany;
  final String registerCompanyHelper;
  final String registerDerivedTitle;
  final String registerDob;
  final String registerGender;
  final String registerGovernorate;
  final String registerAcceptTerms;
  final String registerAcceptMarketing;
  final String registerSubmit;

  final String errorNameFourParts;
  final String errorNationalIdLength;
  final String errorNationalIdInvalid;
  final String errorPhoneInvalid;
  final String errorEmailInvalid;
  final String errorMustAcceptTerms;

  final String genderMale;
  final String genderFemale;

  final String tabHome;
  final String tabServices;
  final String tabFile;
  final String tabBookings;
  final String tabMore;
  final String tabPractice;

  final String homeGreeting;
  final String homeMrn;
  final String homeNextAppointment;
  final String homeResultsReady;
  final String homeQuickServices;
  final String homeCare;
  final String homeComplaints;
  final String homeTips;
  final String homeOffers;

  final String emergencyCall;
  final String emergencyTitle;

  final String servicesTitle;
  final String serviceClinics;
  final String serviceRadiology;
  final String serviceLab;
  final String serviceBloodBank;
  final String serviceSurgery;
  final String serviceCentres;
  final String serviceVisitingExperts;

  final String clinicsTitle;
  final String clinicsChoose;
  final String clinicConsultationFee;
  final String clinicFollowUpFee;
  final String clinicBookNow;
  final String clinicChooseDoctor;
  final String clinicFirstAvailable;
  final String clinicChooseSlot;
  final String clinicNoSlots;

  final String bookingConfirmedTitle;
  final String bookingConfirmedBody;
  final String bookingPayAtReception;
  final String bookingAddToCalendar;

  final String radiologyTitle;
  final String radiologyChooseType;
  final String radiologyPrices;
  final String radiologySchedules;
  final String radiologyPreparation;
  final String radiologyAcknowledgePrep;

  final String labTitle;
  final String labPrices;
  final String labResults;
  final String labOffers;
  final String labTurnaround;
  final String labSample;

  final String bloodBankTitle;
  final String bloodBankRequest;
  final String bloodBankDonate;

  final String fileTitle;
  final String fileVitals;
  final String fileVisits;
  final String fileResults;
  final String fileDocuments;
  final String fileBloodGroup;
  final String fileAllergies;
  final String fileChronic;
  final String fileMaternity;
  final String fileGestationalAge;
  final String fileEdd;
  final String fileExport;

  final String resultReady;
  final String resultPending;
  final String resultWithheld;
  final String resultWithheldBody;

  final String surgeryTitle;
  final String surgeryCatalogue;
  final String surgeryMyRequests;
  final String surgeryRequestNew;
  final String surgeryClassification;
  final String surgeryEstimate;
  final String surgeryEstimateNote;
  final String surgeryPreferredSurgeon;
  final String surgeryPreferredDates;
  final String surgeryRequestAck;
  final String surgeryRequestSubmitted;
  final String surgeryRequestSubmittedBody;
  final String surgeryNoRequests;
  final String surgeryDuration;

  final String statusSubmitted;
  final String statusUnderReview;
  final String statusApproved;
  final String statusScheduled;
  final String statusRejected;
  final String statusMoreInfo;
  final String statusCancelled;
  final String statusCompleted;

  final String theatreTitle;
  final String theatreAvailability;
  final String theatreBookDirect;
  final String theatreFree;
  final String theatreBooked;
  final String theatreProvisional;
  final String theatreTurnover;
  final String theatreBlocked;
  final String theatreFreeHours;
  final String theatreToday;
  final String theatreSelectProcedure;
  final String theatreSelectPatient;
  final String theatreConfirmBooking;
  final String theatreBookedOk;
  final String theatreConflictTheatre;
  final String theatreConflictSurgeon;
  final String theatreConflictPatient;
  final String theatreConflictEquipment;
  final String theatreConflictBlocked;
  final String theatreWarnTheatreType;
  final String theatreWarnSeniority;
  final String theatreWarnOutsideHours;
  final String theatreOverride;
  final String theatreOverrideReason;
  final String theatreNoApprovalNeeded;

  final String centresTitle;
  final String centreSpecialties;
  final String centreProcedures;
  final String centreClinics;

  final String visitingTitle;
  final String visitingExpert;
  final String visitingHost;
  final String visitingWindow;
  final String visitingRegisterInterest;
  final String visitingBookScreening;
  final String visitingInterestDone;
  final String visitingSeats;
  final String visitingStageInterest;
  final String visitingStageScreening;
  final String visitingStageShortlisted;
  final String visitingStageScheduled;
  final String visitingStageWaitlisted;

  final String homeCareTitle;
  final String homeCareRequest;
  final String homeCareCoverage;

  final String complaintsTitle;
  final String complaintsNew;
  final String complaintsCategory;
  final String complaintsBody;
  final String complaintsAnonymous;
  final String complaintsAnonymousNote;
  final String complaintsSubmit;
  final String complaintsReference;
  final String complaintsSla;

  final String offersTitle;
  final String offersEvents;
  final String offersValidUntil;
  final String offersBefore;
  final String offersAfter;

  final String tipsTitle;
  final String tipsDisclaimer;
  final String tipsReviewedBy;

  final String contactTitle;
  final String contactCall;
  final String contactWhatsapp;
  final String contactAmbulance;
  final String contactAmbulanceNote;
  final String contactDirections;

  final String moreTitle;
  final String moreLanguage;
  final String moreAppearance;
  final String moreNotifications;
  final String morePrivacy;
  final String moreAbout;
  final String moreSignOut;
  final String moreSignIn;

  final String aboutDevelopedBy;
  final String aboutVisitWebsite;
  final String aboutSupport;

  final String themeSystem;
  final String themeLight;
  final String themeDark;

  final String guestBannerTitle;
  final String guestBannerBody;
  final String guestBannerAction;

  final String approvalsTitle;
  final String approvalsPending;
  final String approvalsDecided;
  final String approvalsEmpty;
  final String approvalsApprove;
  final String approvalsReject;
  final String approvalsMoreInfo;
  final String approvalsRejectReason;
  final String approvalsDueIn;
  final String approvalsOverdue;
  final String approvalsRunEscalation;
  final String approvalsEscalated;
  final String approvalsApprovedNote;
  final String approvalsMoreInfoNote;
  final String notificationsEmpty;
  final String notificationsNoPhi;
  final String channelPush;
  final String channelWhatsapp;
  final String channelSms;
  final String channelInApp;
  final String channelTemplateApproved;
  final String homeCareAddress;
  final String homeCareWindow;
  final String homeCareNotes;
  final String homeCareSubmitted;
  final String homeCareMyRequests;
  final String homeCareFreeCancel;
  final String bloodGroup;
  final String bloodComponent;
  final String bloodUnits;
  final String bloodRequiredBy;
  final String bloodSubmitted;
  final String bloodLastDonation;
  final String bloodNextEligible;
  final String bloodEligibleNow;
  final String bloodAcceptAppeals;
  final String bloodRegistered;
  final String visitingPipeline;
  final String visitingAddPatient;
  final String visitingAddedByDoctor;
  final String visitingSelfRegistered;
  final String visitingCohortLive;
  final String visitingScreeningBooked;
  final String visitingAdvance;
  final String bookingsTitle;
  final String bookingsEmpty;
  final String bookingsUpcoming;
  final String bookingsPast;

  final String adminConsole;
  final String adminHomeNote;
  final String adminAdd;
  final String adminName;
  final String adminTitle;
  final String adminCode;
  final String adminDescription;
  final String adminCategory;
  final String adminPrice;
  final String adminPriceFrom;
  final String adminPriceTo;
  final String adminColour;
  final String adminInactive;
  final String adminDelete;
  final String adminDeleteConfirm;
  final String adminEnglishFallback;
  final String adminNoReleaseNeeded;
  final String adminClassifications;
  final String adminClassificationsNote;
  final String adminNewClassification;
  final String adminEditClassification;
  final String adminSchedulingDefaults;
  final String adminDefaultsNote;
  final String adminAnaesthesia;
  final String adminRequiredSeniority;
  final String adminSeniorityNote;
  final String adminBloodUnits;
  final String adminBloodNote;
  final String adminSeniority;
  final String adminProcedures;
  final String adminNewProcedure;
  final String adminEditProcedure;
  final String adminTheatreType;
  final String adminCentre;
  final String adminNoCentre;
  final String adminPatientRequestable;
  final String adminPatientRequestableNote;
  final String adminClinics;
  final String adminNewClinic;
  final String adminEditClinic;
  final String adminWorkingDays;
  final String adminDoctors;
  final String adminDoctorsCount;
  final String adminAddDoctorFirst;
  final String adminNewDoctor;
  final String adminEditDoctor;
  final String adminDoctorTitle;
  final String adminSpecialty;
  final String adminTheatres;
  final String adminNewTheatre;
  final String adminEditTheatre;
  final String adminOperatingHours;
  final String adminHoursInvalid;
  final String adminTheatreActive;
  final String adminTheatreActiveNote;
  final String adminOffers;
  final String adminNewOffer;
  final String adminEditOffer;
  final String adminIsEvent;
  final String adminIsEventNote;
  final String adminTips;
  final String adminNewTip;
  final String adminEditTip;
  final String adminTipBody;
  final String adminReviewerName;
  final String adminReviewerRequired;

  final String doctorRequestTitle;
  final String doctorRequestNew;
  final String doctorRequestNote;
  final String doctorRequestNoteLabel;
  final String doctorRequestNoteHelp;
  final String doctorRequestSend;
  final String doctorRequestSent;
  final String doctorRequestSentBody;
  final String scheduleTitle;
  final String scheduleRequestedBy;
  final String scheduleDate;
  final String scheduleTime;
  final String scheduleConfirmedPrice;
  final String scheduleConfirmedPriceHelp;
  final String scheduleConfirm;
  final String scheduleNotifiesDoctor;
  final String scheduleDone;
  final String scheduleAction;
  final String scheduleQueue;
  final String requestFromDoctor;
  final String requestFromPatient;
  final String adminPolicy;
  final String policyDirectBooking;
  final String policyDirectBookingOn;
  final String policyDirectBookingOff;
  final String policyNotifyOnChange;
  final String policyNotifyOnChangeNote;
  final String policyNotifyOffWarning;
  final String policyApprovalWindow;
  final String policyApprovalWindowNote;
  final String policyCancellationCutoff;
  final String policyCancellationNote;
  final String policyDefaultPayment;
  final String adminUsers;
  final String adminNewUser;
  final String adminEditUser;
  final String adminRoles;
  final String adminRolesNote;
  final String adminApprovalCoverageThin;
  final String adminLinkedDoctor;
  final String adminLinkedDoctorNote;
  final String adminAudit;
  final String adminAuditEmpty;
  final String adminAuditNote;
  final String permManageCatalogue;
  final String permManageUsers;
  final String permApprove;
  final String permSchedule;
  final String permBookDirect;
  final String permOverride;
  final String permAudit;
  final String adminShifts;
  final String adminShiftsNote;
  final String adminShiftFrom;
  final String adminShiftTo;
  final String adminMaxPatients;
  final String adminNoCap;
  final String adminWeeklyCapacity;
  final String adminSlotLength;
  final String adminNoShift;
  final String adminPaymentPolicy;
  final String adminDepositAmount;
  final String adminAffectedBookings;
  final String adminAffectedWarning;
  final String adminSaveAnyway;
  final String bookingPayNow;
  final String bookingPayLater;
  final String bookingDepositNote;
  final String bookingDepositPaid;
  final String bookingBalanceDue;
  final String bookingFreeNote;
  final String bookingCancelled;
  final String bookingRebook;
  final String capacityFull;
  final String capacityRemaining;

  static const AppStrings ar = AppStrings(
    localeName: 'ar',
    appName: 'دار الأمومة',
    tagline: 'صحتك مسؤوليتنا',
    brandLine: 'دار الأمومة في بيتك',
    commonNext: 'التالي',
    commonBack: 'رجوع',
    commonCancel: 'إلغاء',
    commonConfirm: 'تأكيد',
    commonSave: 'حفظ',
    commonClose: 'إغلاق',
    commonSearch: 'بحث',
    commonRetry: 'إعادة المحاولة',
    commonAll: 'الكل',
    commonFrom: 'من',
    commonTo: 'إلى',
    commonOptional: 'اختياري',
    commonRequired: 'مطلوب',
    commonEgp: 'جنيه',
    commonMinutes: 'دقيقة',
    commonNoResults: 'لا توجد نتائج',
    commonComingSoon: 'قريبًا',
    commonSomethingWentWrong: 'حدث خطأ، برجاء المحاولة مرة أخرى',
    welcomeLogin: 'تسجيل دخول',
    welcomeRegister: 'إنشاء حساب',
    welcomeGuest: 'الدخول كزائر',
    loginTitle: 'تسجيل الدخول',
    loginSubtitle: 'أدخل رقم هاتفك وسنرسل لك رمز تحقق',
    loginPhoneLabel: 'رقم الهاتف',
    loginPhoneHint: '01xxxxxxxxx',
    loginSendOtp: 'إرسال رمز التحقق',
    loginDemoHint: 'نسخة تجريبية: استخدم الرمز 123456',
    otpTitle: 'رمز التحقق',
    otpSubtitle: 'أدخل الرمز المكوّن من 6 أرقام المرسل إلى',
    otpVerify: 'تحقق',
    otpResend: 'إعادة الإرسال',
    otpInvalid: 'الرمز غير صحيح',
    registerTitle: 'سجل بياناتك',
    registerSubtitle: 'بياناتك محفوظة وسرّية ولا تُستخدم إلا لخدمتك الطبية',
    registerFullName: 'الاسم رباعي',
    registerNationalId: 'الرقم القومي',
    registerPhone: 'رقم الهاتف',
    registerEmail: 'البريد الإلكتروني',
    registerCompany: 'اسم الشركة إن وجد',
    registerCompanyHelper: 'لو لديك تعاقد تأميني أو تعاقد شركة مع المستشفى',
    registerDerivedTitle: 'بيانات مستخرجة من الرقم القومي — برجاء المراجعة',
    registerDob: 'تاريخ الميلاد',
    registerGender: 'النوع',
    registerGovernorate: 'محافظة الميلاد',
    registerAcceptTerms: 'أوافق على شروط الاستخدام وسياسة الخصوصية',
    registerAcceptMarketing: 'أوافق على استقبال العروض والرسائل التسويقية',
    registerSubmit: 'إنشاء الحساب',
    errorNameFourParts: 'برجاء إدخال الاسم رباعيًا',
    errorNationalIdLength: 'الرقم القومي يجب أن يكون 14 رقمًا',
    errorNationalIdInvalid: 'الرقم القومي غير صحيح',
    errorPhoneInvalid: 'رقم هاتف غير صحيح',
    errorEmailInvalid: 'بريد إلكتروني غير صحيح',
    errorMustAcceptTerms: 'يجب الموافقة على الشروط للمتابعة',
    genderMale: 'ذكر',
    genderFemale: 'أنثى',
    tabHome: 'الرئيسية',
    tabServices: 'الخدمات',
    tabFile: 'ملفي',
    tabBookings: 'حجوزاتي',
    tabMore: 'المزيد',
    tabPractice: 'عيادتي',
    homeGreeting: 'أهلًا',
    homeMrn: 'رقم الملف',
    homeNextAppointment: 'موعدك القادم',
    homeResultsReady: 'نتائج جاهزة',
    homeQuickServices: 'خدمات سريعة',
    homeCare: 'الرعاية المنزلية',
    homeComplaints: 'الشكاوى',
    homeTips: 'نصائح طبية',
    homeOffers: 'العروض',
    emergencyCall: 'طوارئ',
    emergencyTitle: 'اتصال الطوارئ',
    servicesTitle: 'الخدمات',
    serviceClinics: 'العيادات',
    serviceRadiology: 'الأشعة',
    serviceLab: 'التحاليل',
    serviceBloodBank: 'بنك الدم',
    serviceSurgery: 'العمليات',
    serviceCentres: 'المراكز التخصصية',
    serviceVisitingExperts: 'الخبراء الزائرون',
    clinicsTitle: 'العيادات',
    clinicsChoose: 'اختر عيادة',
    clinicConsultationFee: 'الكشف',
    clinicFollowUpFee: 'الاستشارة',
    clinicBookNow: 'احجز الآن',
    clinicChooseDoctor: 'اختر الطبيب',
    clinicFirstAvailable: 'أقرب طبيب متاح',
    clinicChooseSlot: 'اختر الموعد',
    clinicNoSlots: 'لا توجد مواعيد متاحة في هذا اليوم',
    bookingConfirmedTitle: 'تم تأكيد الحجز',
    bookingConfirmedBody: 'ستصلك رسالة تأكيد وتذكير قبل الموعد',
    bookingPayAtReception: 'الدفع في الاستقبال',
    bookingAddToCalendar: 'إضافة إلى التقويم',
    radiologyTitle: 'الأشعة',
    radiologyChooseType: 'اختر نوع الأشعة',
    radiologyPrices: 'أسعار الأشعة',
    radiologySchedules: 'مواعيد الأشعة',
    radiologyPreparation: 'تعليمات التحضير',
    radiologyAcknowledgePrep: 'أقررت بقراءة تعليمات التحضير',
    labTitle: 'التحاليل وبنك الدم',
    labPrices: 'أسعار التحاليل',
    labResults: 'نتائج التحاليل',
    labOffers: 'العروض',
    labTurnaround: 'مدة النتيجة',
    labSample: 'العينة',
    bloodBankTitle: 'خدمات بنك الدم',
    bloodBankRequest: 'طلب وحدات دم',
    bloodBankDonate: 'التسجيل كمتبرع',
    fileTitle: 'الملف الطبي',
    fileVitals: 'العلامات الحيوية',
    fileVisits: 'الزيارات',
    fileResults: 'النتائج',
    fileDocuments: 'المستندات والفواتير',
    fileBloodGroup: 'فصيلة الدم',
    fileAllergies: 'الحساسية',
    fileChronic: 'أمراض مزمنة',
    fileMaternity: 'متابعة الحمل',
    fileGestationalAge: 'عمر الحمل',
    fileEdd: 'الموعد المتوقع للولادة',
    fileExport: 'تصدير الملف PDF',
    resultReady: 'جاهزة',
    resultPending: 'قيد التنفيذ',
    resultWithheld: 'بانتظار مراجعة الطبيب',
    resultWithheldBody:
        'هذه النتيجة تحتاج مراجعة طبية قبل عرضها. برجاء التواصل مع المستشفى.',
    surgeryTitle: 'العمليات',
    surgeryCatalogue: 'قائمة العمليات',
    surgeryMyRequests: 'طلباتي',
    surgeryRequestNew: 'طلب حجز عملية',
    surgeryClassification: 'التصنيف',
    surgeryEstimate: 'التكلفة التقديرية',
    surgeryEstimateNote:
        'هذا تقدير مبدئي وقد يتغير بعد التقييم الطبي ولا يشمل المستلزمات الخاصة.',
    surgeryPreferredSurgeon: 'الطبيب المفضل',
    surgeryPreferredDates: 'الفترة المفضلة',
    surgeryRequestAck:
        'أفهم أن هذا طلب وليس حجزًا مؤكدًا، وأنه يخضع للمراجعة الطبية والموافقة.',
    surgeryRequestSubmitted: 'تم إرسال طلبك',
    surgeryRequestSubmittedBody:
        'تم إخطار الإدارة الطبية وسيتم الرد عليك في أقرب وقت.',
    surgeryNoRequests: 'لا توجد طلبات',
    surgeryDuration: 'المدة المتوقعة',
    statusSubmitted: 'تم الإرسال',
    statusUnderReview: 'قيد المراجعة',
    statusApproved: 'تمت الموافقة',
    statusScheduled: 'تم تحديد موعد',
    statusRejected: 'مرفوض',
    statusMoreInfo: 'مطلوب بيانات إضافية',
    statusCancelled: 'ملغي',
    statusCompleted: 'مكتمل',
    theatreTitle: 'غرف العمليات',
    theatreAvailability: 'الفاضي والمحجوز',
    theatreBookDirect: 'حجز مباشر',
    theatreFree: 'متاح',
    theatreBooked: 'محجوز',
    theatreProvisional: 'بانتظار الموافقة',
    theatreTurnover: 'تجهيز',
    theatreBlocked: 'صيانة',
    theatreFreeHours: 'ساعات متاحة',
    theatreToday: 'اليوم',
    theatreSelectProcedure: 'اختر العملية',
    theatreSelectPatient: 'اختر المريض',
    theatreConfirmBooking: 'تأكيد الحجز',
    theatreBookedOk: 'تم الحجز مباشرة بدون الحاجة لموافقة',
    theatreConflictTheatre: 'الغرفة محجوزة في هذا الوقت',
    theatreConflictSurgeon: 'الطبيب لديه ارتباط آخر في هذا الوقت',
    theatreConflictPatient: 'المريض لديه حجز آخر في هذا الوقت',
    theatreConflictEquipment: 'الأجهزة المطلوبة محجوزة لعملية أخرى',
    theatreConflictBlocked: 'الغرفة خارج الخدمة للصيانة',
    theatreWarnTheatreType: 'نوع الغرفة لا يطابق متطلبات العملية',
    theatreWarnSeniority: 'درجة الجراح أقل من المطلوب لهذا التصنيف',
    theatreWarnOutsideHours: 'الحجز خارج ساعات العمل المعتادة للغرفة',
    theatreOverride: 'تجاوز التعارض',
    theatreOverrideReason: 'سبب التجاوز (إلزامي)',
    theatreNoApprovalNeeded: 'الحجز يتم فورًا بدون انتظار موافقة',
    centresTitle: 'المراكز التخصصية',
    centreSpecialties: 'التخصصات',
    centreProcedures: 'العمليات',
    centreClinics: 'العيادات',
    visitingTitle: 'الخبراء الزائرون',
    visitingExpert: 'الخبير الزائر',
    visitingHost: 'الطبيب المضيف',
    visitingWindow: 'فترة الزيارة',
    visitingRegisterInterest: 'تسجيل الاهتمام',
    visitingBookScreening: 'حجز موعد فرز',
    visitingInterestDone: 'تم تسجيل اهتمامك، سنتواصل معك لتحديد موعد الفرز',
    visitingSeats: 'الأماكن المتاحة',
    visitingStageInterest: 'مسجّل اهتمام',
    visitingStageScreening: 'موعد فرز',
    visitingStageShortlisted: 'مرشّح',
    visitingStageScheduled: 'تم تحديد موعد العملية',
    visitingStageWaitlisted: 'قائمة انتظار',
    homeCareTitle: 'الرعاية المنزلية',
    homeCareRequest: 'اطلب الخدمة',
    homeCareCoverage: 'نطاق التغطية',
    complaintsTitle: 'الشكاوى',
    complaintsNew: 'شكوى جديدة',
    complaintsCategory: 'نوع الشكوى',
    complaintsBody: 'تفاصيل الشكوى',
    complaintsAnonymous: 'إرسال بدون ذكر الاسم',
    complaintsAnonymousNote:
        'الشكوى المجهولة لا يمكن تتبع حالتها ولن تصلك ردود عليها.',
    complaintsSubmit: 'إرسال الشكوى',
    complaintsReference: 'رقم المرجع',
    complaintsSla: 'نرد خلال 24 ساعة ونعالج الشكوى خلال 72 ساعة',
    offersTitle: 'العروض',
    offersEvents: 'الفعاليات',
    offersValidUntil: 'ساري حتى',
    offersBefore: 'قبل',
    offersAfter: 'بعد',
    tipsTitle: 'نصائح طبية',
    tipsDisclaimer:
        'هذه معلومات صحية عامة ولا تغني عن استشارة الطبيب المختص.',
    tipsReviewedBy: 'مراجعة طبية',
    contactTitle: 'اتصل بنا',
    contactCall: 'اتصال',
    contactWhatsapp: 'واتساب',
    contactAmbulance: 'طلب إسعاف',
    contactAmbulanceNote:
        'الاتصال الهاتفي هو القناة المعتمدة للطوارئ. الطلب من التطبيق مساعد فقط.',
    contactDirections: 'الاتجاهات',
    moreTitle: 'المزيد',
    moreLanguage: 'اللغة',
    moreAppearance: 'المظهر',
    moreNotifications: 'الإشعارات',
    morePrivacy: 'الخصوصية والموافقات',
    moreAbout: 'عن التطبيق',
    moreSignOut: 'تسجيل الخروج',
    moreSignIn: 'تسجيل الدخول',
    aboutDevelopedBy: 'تطوير',
    aboutVisitWebsite: 'زيارة الموقع',
    aboutSupport: 'الدعم الفني',
    themeSystem: 'حسب النظام',
    themeLight: 'فاتح',
    themeDark: 'داكن',
    guestBannerTitle: 'أنت تتصفح كزائر',
    guestBannerBody: 'سجّل الدخول للحجز والاطلاع على ملفك الطبي ونتائجك.',
    guestBannerAction: 'تسجيل الدخول',
    approvalsTitle: 'صندوق الموافقات',
    approvalsPending: 'بانتظار القرار',
    approvalsDecided: 'تم البت فيها',
    approvalsEmpty: 'لا توجد طلبات بانتظار الموافقة',
    approvalsApprove: 'موافقة',
    approvalsReject: 'رفض',
    approvalsMoreInfo: 'طلب بيانات إضافية',
    approvalsRejectReason: 'سبب الرفض',
    approvalsDueIn: 'متبقٍ للرد',
    approvalsOverdue: 'تجاوز مهلة الرد — تم التصعيد للإدارة الطبية',
    approvalsRunEscalation: 'تشغيل التصعيد',
    approvalsEscalated: 'طلبات تم تصعيدها',
    approvalsApprovedNote: 'تمت الموافقة، سيتم التواصل معك لتحديد الموعد.',
    approvalsMoreInfoNote: 'برجاء رفع التقارير والفحوصات السابقة.',
    notificationsEmpty: 'لا توجد إشعارات',
    notificationsNoPhi: 'رسائل الواتساب والـ SMS تحمل رقمًا مرجعيًا ورابطًا فقط — بدون أي بيانات طبية.',
    channelPush: 'إشعار',
    channelWhatsapp: 'واتساب',
    channelSms: 'رسالة نصية',
    channelInApp: 'داخل التطبيق',
    channelTemplateApproved: 'قالب معتمد',
    homeCareAddress: 'العنوان',
    homeCareWindow: 'الموعد المفضل',
    homeCareNotes: 'ملاحظات',
    homeCareSubmitted: 'تم استلام طلبك',
    homeCareMyRequests: 'طلباتي',
    homeCareFreeCancel: 'الإلغاء مجاني حتى تحرك الفريق إليك.',
    bloodGroup: 'فصيلة الدم',
    bloodComponent: 'المكوّن',
    bloodUnits: 'عدد الوحدات',
    bloodRequiredBy: 'مطلوب بحلول',
    bloodSubmitted: 'تم إرسال الطلب لبنك الدم',
    bloodLastDonation: 'آخر تبرع',
    bloodNextEligible: 'موعد الأهلية القادم',
    bloodEligibleNow: 'مؤهل للتبرع الآن',
    bloodAcceptAppeals: 'أوافق على استقبال نداءات التبرع العاجلة',
    bloodRegistered: 'تم تسجيلك كمتبرع',
    visitingPipeline: 'مسار الحالات',
    visitingAddPatient: 'إضافة مريض',
    visitingAddedByDoctor: 'أضافه الطبيب',
    visitingSelfRegistered: 'تسجيل ذاتي',
    visitingCohortLive: 'الحالات المؤكدة',
    visitingScreeningBooked: 'تم حجز موعد الفرز',
    visitingAdvance: 'المرحلة التالية',
    bookingsTitle: 'حجوزاتي',
    bookingsEmpty: 'لا توجد حجوزات',
    bookingsUpcoming: 'القادمة',
    bookingsPast: 'السابقة',
    adminConsole: 'لوحة التحكم',
    adminHomeNote: 'التعديلات هنا تظهر للمرضى والأطباء فورًا بدون تحديث للتطبيق.',
    adminAdd: 'إضافة',
    adminName: 'الاسم',
    adminTitle: 'العنوان',
    adminCode: 'الكود',
    adminDescription: 'الوصف',
    adminCategory: 'التصنيف',
    adminPrice: 'السعر',
    adminPriceFrom: 'السعر من',
    adminPriceTo: 'السعر إلى',
    adminColour: 'اللون',
    adminInactive: 'موقوف',
    adminDelete: 'حذف',
    adminDeleteConfirm: 'تأكيد الحذف',
    adminEnglishFallback: 'لو سيبتها فاضية هيظهر النص العربي.',
    adminNoReleaseNeeded: 'المحتوى ده بيتنشر من غير ما ترفع نسخة جديدة على الستور.',
    adminClassifications: 'تصنيفات العمليات',
    adminClassificationsNote: 'التصنيفات بيانات مش كود — تضيف وتعدّل وتوقف من هنا، والتغيير يظهر في شاشة الحجز والجريد فورًا.',
    adminNewClassification: 'تصنيف جديد',
    adminEditClassification: 'تعديل التصنيف',
    adminSchedulingDefaults: 'الافتراضات',
    adminDefaultsNote: 'القيم دي بتملّي شاشة حجز العملية لوحدها، والطبيب يقدر يعدّلها.',
    adminAnaesthesia: 'نوع التخدير',
    adminRequiredSeniority: 'درجة الجراح المطلوبة',
    adminSeniorityNote: 'لو الجراح درجته أقل، الحجز بيتم مع تنبيه لرئيس القسم — مش بيتمنع.',
    adminBloodUnits: 'وحدات الدم المحجوزة',
    adminBloodNote: 'بيتحجزوا تلقائيًا في بنك الدم مع كل عملية بالتصنيف ده.',
    adminSeniority: 'الدرجة',
    adminProcedures: 'العمليات',
    adminNewProcedure: 'عملية جديدة',
    adminEditProcedure: 'تعديل العملية',
    adminTheatreType: 'نوع غرفة العمليات',
    adminCentre: 'المركز التخصصي',
    adminNoCentre: 'بدون مركز',
    adminPatientRequestable: 'المريض يقدر يطلبها من التطبيق',
    adminPatientRequestableNote: 'لو قفلتها، العملية تفضل متاحة للأطباء بس.',
    adminClinics: 'العيادات',
    adminNewClinic: 'عيادة جديدة',
    adminEditClinic: 'تعديل العيادة',
    adminWorkingDays: 'أيام العمل',
    adminDoctors: 'الأطباء',
    adminDoctorsCount: 'طبيب',
    adminAddDoctorFirst: 'ضيف طبيب الأول من قسم الأطباء.',
    adminNewDoctor: 'طبيب جديد',
    adminEditDoctor: 'تعديل الطبيب',
    adminDoctorTitle: 'الدرجة العلمية',
    adminSpecialty: 'التخصص',
    adminTheatres: 'غرف العمليات',
    adminNewTheatre: 'غرفة جديدة',
    adminEditTheatre: 'تعديل الغرفة',
    adminOperatingHours: 'ساعات العمل',
    adminHoursInvalid: 'ساعة القفل لازم تكون بعد ساعة الفتح.',
    adminTheatreActive: 'الغرفة في الخدمة',
    adminTheatreActiveNote: 'لو قفلتها، مش هينفع الحجز فيها.',
    adminOffers: 'العروض والفعاليات',
    adminNewOffer: 'عرض جديد',
    adminEditOffer: 'تعديل العرض',
    adminIsEvent: 'فعالية توعية',
    adminIsEventNote: 'الفعاليات بتظهر في قسم منفصل وبدون أسعار.',
    adminTips: 'النصائح الطبية',
    adminNewTip: 'نصيحة جديدة',
    adminEditTip: 'تعديل النصيحة',
    adminTipBody: 'نص النصيحة',
    adminReviewerName: 'اسم المراجع الطبي',
    adminReviewerRequired: 'ممنوع نشر نصيحة من غير مراجع طبي بالاسم.',
    doctorRequestTitle: 'طلب غرفة عمليات',
    doctorRequestNew: 'طلب جديد',
    doctorRequestNote: 'الإدارة هي اللي هتحدد الغرفة والموعد والسعر، وهيوصلك إشعار بالتفاصيل بعد التأكيد.',
    doctorRequestNoteLabel: 'ملاحظات للإدارة',
    doctorRequestNoteHelp: 'درجة الاستعجال، أجهزة مطلوبة، أي قيود على الموعد.',
    doctorRequestSend: 'إرسال الطلب',
    doctorRequestSent: 'تم إرسال الطلب',
    doctorRequestSentBody: 'تم إخطار الإدارة، وهيوصلك إشعار أول ما يتحدد الموعد.',
    scheduleTitle: 'تحديد موعد العملية',
    scheduleRequestedBy: 'مقدّم الطلب',
    scheduleDate: 'التاريخ',
    scheduleTime: 'الساعة',
    scheduleConfirmedPrice: 'السعر النهائي',
    scheduleConfirmedPriceHelp: 'ده السعر اللي المستشفى بتلتزم بيه، مش التقدير المبدئي.',
    scheduleConfirm: 'تأكيد الحجز',
    scheduleNotifiesDoctor: 'هيتبعت إشعار للطبيب وللمريض بتفاصيل الحجز.',
    scheduleDone: 'تم تأكيد الحجز وإخطار الطبيب',
    scheduleAction: 'تحديد الموعد',
    scheduleQueue: 'بانتظار تحديد موعد',
    requestFromDoctor: 'طلب طبيب',
    requestFromPatient: 'طلب مريض',
    adminPolicy: 'السياسات والإعدادات',
    policyDirectBooking: 'الأطباء يحجزوا غرف العمليات مباشرة',
    policyDirectBookingOn: 'الطبيب بيحجز بنفسه فورًا، مع تطبيق قواعد التعارض. أسرع، بس التحكم في الجدول لامركزي.',
    policyDirectBookingOff: 'الطبيب بيبعت طلب، والإدارة بتحدد الغرفة والموعد والسعر وتأكد. تحكم أعلى، بس أبطأ.',
    policyNotifyOnChange: 'إخطار المرضى عند تعديل المواعيد',
    policyNotifyOnChangeNote: 'لما تتغير أيام العيادة أو مواعيد الطبيب، الحجوزات المتأثرة تتلغي والمريض يتبلّغ ويقدر يحجز من جديد.',
    policyNotifyOffWarning: 'إيقافها معناه إن المريض هيكتشف الإلغاء لما ييجي المستشفى. مش منصوح بيه.',
    policyApprovalWindow: 'مهلة الرد على الطلبات',
    policyApprovalWindowNote: 'بعد المهلة دي الطلب بيتصعّد للإدارة الطبية.',
    policyCancellationCutoff: 'آخر ميعاد لإلغاء الحجز',
    policyCancellationNote: 'قبل الموعد بالمدة دي المريض يقدر يلغي بنفسه.',
    policyDefaultPayment: 'سياسة الدفع الافتراضية',
    adminUsers: 'المستخدمون والصلاحيات',
    adminNewUser: 'مستخدم جديد',
    adminEditUser: 'تعديل المستخدم',
    adminRoles: 'الأدوار',
    adminRolesNote: 'الشخص الواحد ممكن ياخد أكتر من دور، والصلاحيات بتتجمع.',
    adminApprovalCoverageThin: 'فيه شخص واحد بس يقدر يوافق على العمليات. لو غاب، طلبات المرضى هتتعطل — ضيف تاني.',
    adminLinkedDoctor: 'ربط بملف الطبيب',
    adminLinkedDoctorNote: 'الربط بيخلي الحساب يشوف جدوله وقائمة عملياته.',
    adminAudit: 'سجل التغييرات',
    adminAuditEmpty: 'مفيش تغييرات مسجّلة',
    adminAuditNote: 'السجل بيتكتب ومابيتعدلش ولا بيتمسح.',
    permManageCatalogue: 'إدارة الكتالوج',
    permManageUsers: 'إدارة المستخدمين',
    permApprove: 'الموافقة على العمليات',
    permSchedule: 'تحديد المواعيد',
    permBookDirect: 'حجز مباشر',
    permOverride: 'تجاوز التعارض',
    permAudit: 'عرض السجل',
    adminShifts: 'مواعيد العمل والسعة',
    adminShiftsNote: 'حدد الطبيب بيشتغل إيه أيام ومن كام لكام، وكام مريض أقصى عدد. المواعيد المتاحة للمريض بتتولد من ده.',
    adminShiftFrom: 'من',
    adminShiftTo: 'إلى',
    adminMaxPatients: 'أقصى عدد مرضى',
    adminNoCap: 'بدون حد',
    adminWeeklyCapacity: 'السعة الأسبوعية',
    adminSlotLength: 'مدة الكشف',
    adminNoShift: 'مش شغال',
    adminPaymentPolicy: 'سياسة الدفع',
    adminDepositAmount: 'قيمة العربون',
    adminAffectedBookings: 'حجوزات هتتأثر',
    adminAffectedWarning: 'التعديل ده هيلغي الحجوزات دي، وهيتبعت للمرضى إشعار بالإلغاء وإن المواعيد اتغيرت.',
    adminSaveAnyway: 'احفظ وألغِ الحجوزات',
    bookingPayNow: 'ادفع الآن',
    bookingPayLater: 'ادفع في الاستقبال',
    bookingDepositNote: 'العربون بيحجزلك المكان، والباقي بيتدفع في الاستقبال.',
    bookingDepositPaid: 'تم دفع العربون',
    bookingBalanceDue: 'المتبقي',
    bookingFreeNote: 'الحجز مجاني، والدفع في الاستقبال.',
    bookingCancelled: 'تم إلغاء الموعد',
    bookingRebook: 'احجز موعد جديد',
    capacityFull: 'اكتمل العدد لهذا اليوم',
    capacityRemaining: 'أماكن متبقية',
  );

  static const AppStrings en = AppStrings(
    localeName: 'en',
    appName: 'Dar El Omouma',
    tagline: 'Your health is our responsibility',
    brandLine: 'Dar El Omouma, at your home',
    commonNext: 'Next',
    commonBack: 'Back',
    commonCancel: 'Cancel',
    commonConfirm: 'Confirm',
    commonSave: 'Save',
    commonClose: 'Close',
    commonSearch: 'Search',
    commonRetry: 'Retry',
    commonAll: 'All',
    commonFrom: 'From',
    commonTo: 'To',
    commonOptional: 'Optional',
    commonRequired: 'Required',
    commonEgp: 'EGP',
    commonMinutes: 'min',
    commonNoResults: 'No results',
    commonComingSoon: 'Coming soon',
    commonSomethingWentWrong: 'Something went wrong. Please try again.',
    welcomeLogin: 'Log in',
    welcomeRegister: 'Create account',
    welcomeGuest: 'Continue as guest',
    loginTitle: 'Log in',
    loginSubtitle: 'Enter your phone number and we will send you a code',
    loginPhoneLabel: 'Phone number',
    loginPhoneHint: '01xxxxxxxxx',
    loginSendOtp: 'Send code',
    loginDemoHint: 'Demo build: use code 123456',
    otpTitle: 'Verification code',
    otpSubtitle: 'Enter the 6-digit code sent to',
    otpVerify: 'Verify',
    otpResend: 'Resend',
    otpInvalid: 'Incorrect code',
    registerTitle: 'Create your account',
    registerSubtitle:
        'Your data is confidential and used only for your medical care',
    registerFullName: 'Full name (four parts)',
    registerNationalId: 'National ID',
    registerPhone: 'Phone number',
    registerEmail: 'Email',
    registerCompany: 'Company name (if any)',
    registerCompanyHelper:
        'If you have an insurance or corporate contract with the hospital',
    registerDerivedTitle: 'Derived from your National ID — please confirm',
    registerDob: 'Date of birth',
    registerGender: 'Gender',
    registerGovernorate: 'Governorate of birth',
    registerAcceptTerms: 'I accept the Terms of Use and Privacy Notice',
    registerAcceptMarketing: 'I agree to receive offers and marketing messages',
    registerSubmit: 'Create account',
    errorNameFourParts: 'Please enter all four parts of your name',
    errorNationalIdLength: 'National ID must be 14 digits',
    errorNationalIdInvalid: 'This National ID is not valid',
    errorPhoneInvalid: 'Invalid phone number',
    errorEmailInvalid: 'Invalid email address',
    errorMustAcceptTerms: 'You must accept the terms to continue',
    genderMale: 'Male',
    genderFemale: 'Female',
    tabHome: 'Home',
    tabServices: 'Services',
    tabFile: 'My file',
    tabBookings: 'Bookings',
    tabMore: 'More',
    tabPractice: 'My practice',
    homeGreeting: 'Hello',
    homeMrn: 'MRN',
    homeNextAppointment: 'Next appointment',
    homeResultsReady: 'Results ready',
    homeQuickServices: 'Quick services',
    homeCare: 'Home care',
    homeComplaints: 'Complaints',
    homeTips: 'Medical tips',
    homeOffers: 'Offers',
    emergencyCall: 'Emergency',
    emergencyTitle: 'Emergency call',
    servicesTitle: 'Services',
    serviceClinics: 'Clinics',
    serviceRadiology: 'Radiology',
    serviceLab: 'Laboratory',
    serviceBloodBank: 'Blood bank',
    serviceSurgery: 'Surgery',
    serviceCentres: 'Specialty centres',
    serviceVisitingExperts: 'Visiting experts',
    clinicsTitle: 'Clinics',
    clinicsChoose: 'Choose a clinic',
    clinicConsultationFee: 'Consultation',
    clinicFollowUpFee: 'Follow-up',
    clinicBookNow: 'Book now',
    clinicChooseDoctor: 'Choose a doctor',
    clinicFirstAvailable: 'First available',
    clinicChooseSlot: 'Choose a time',
    clinicNoSlots: 'No slots available on this day',
    bookingConfirmedTitle: 'Booking confirmed',
    bookingConfirmedBody: 'You will receive a confirmation and a reminder',
    bookingPayAtReception: 'Pay at reception',
    bookingAddToCalendar: 'Add to calendar',
    radiologyTitle: 'Radiology',
    radiologyChooseType: 'Choose the study type',
    radiologyPrices: 'Prices',
    radiologySchedules: 'Schedules',
    radiologyPreparation: 'Preparation instructions',
    radiologyAcknowledgePrep: 'I have read the preparation instructions',
    labTitle: 'Laboratory & blood bank',
    labPrices: 'Test prices',
    labResults: 'Results',
    labOffers: 'Offers',
    labTurnaround: 'Turnaround',
    labSample: 'Sample',
    bloodBankTitle: 'Blood bank services',
    bloodBankRequest: 'Request blood units',
    bloodBankDonate: 'Register as a donor',
    fileTitle: 'Medical file',
    fileVitals: 'Vitals',
    fileVisits: 'Visits',
    fileResults: 'Results',
    fileDocuments: 'Documents & invoices',
    fileBloodGroup: 'Blood group',
    fileAllergies: 'Allergies',
    fileChronic: 'Chronic conditions',
    fileMaternity: 'Pregnancy',
    fileGestationalAge: 'Gestational age',
    fileEdd: 'Expected delivery date',
    fileExport: 'Export file as PDF',
    resultReady: 'Ready',
    resultPending: 'In progress',
    resultWithheld: 'Awaiting clinician review',
    resultWithheldBody:
        'This result requires medical review before release. Please contact the hospital.',
    surgeryTitle: 'Surgery',
    surgeryCatalogue: 'Procedures',
    surgeryMyRequests: 'My requests',
    surgeryRequestNew: 'Request a surgery',
    surgeryClassification: 'Classification',
    surgeryEstimate: 'Estimated cost',
    surgeryEstimateNote:
        'This is an estimate and may change after clinical assessment. It excludes special consumables.',
    surgeryPreferredSurgeon: 'Preferred surgeon',
    surgeryPreferredDates: 'Preferred period',
    surgeryRequestAck:
        'I understand this is a request, not a confirmed booking, and is subject to medical review and approval.',
    surgeryRequestSubmitted: 'Request submitted',
    surgeryRequestSubmittedBody:
        'The medical administration has been notified and will respond shortly.',
    surgeryNoRequests: 'No requests yet',
    surgeryDuration: 'Expected duration',
    statusSubmitted: 'Submitted',
    statusUnderReview: 'Under review',
    statusApproved: 'Approved',
    statusScheduled: 'Scheduled',
    statusRejected: 'Rejected',
    statusMoreInfo: 'More information needed',
    statusCancelled: 'Cancelled',
    statusCompleted: 'Completed',
    theatreTitle: 'Operating theatres',
    theatreAvailability: 'Availability',
    theatreBookDirect: 'Book directly',
    theatreFree: 'Available',
    theatreBooked: 'Booked',
    theatreProvisional: 'Awaiting approval',
    theatreTurnover: 'Turnover',
    theatreBlocked: 'Maintenance',
    theatreFreeHours: 'free hours',
    theatreToday: 'Today',
    theatreSelectProcedure: 'Select procedure',
    theatreSelectPatient: 'Select patient',
    theatreConfirmBooking: 'Confirm booking',
    theatreBookedOk: 'Booked directly — no approval required',
    theatreConflictTheatre: 'This theatre is already booked at that time',
    theatreConflictSurgeon: 'The surgeon has another commitment at that time',
    theatreConflictPatient: 'The patient has another booking at that time',
    theatreConflictEquipment: 'Required equipment is committed to another case',
    theatreConflictBlocked: 'The theatre is out of service for maintenance',
    theatreWarnTheatreType: 'Theatre type does not match the procedure',
    theatreWarnSeniority:
        'Surgeon seniority is below this classification requirement',
    theatreWarnOutsideHours: 'Booking is outside normal theatre hours',
    theatreOverride: 'Override conflict',
    theatreOverrideReason: 'Reason for override (required)',
    theatreNoApprovalNeeded: 'Booking is immediate — no approval required',
    centresTitle: 'Specialty centres',
    centreSpecialties: 'Specialties',
    centreProcedures: 'Procedures',
    centreClinics: 'Clinics',
    visitingTitle: 'Visiting experts',
    visitingExpert: 'Visiting expert',
    visitingHost: 'Host doctor',
    visitingWindow: 'Visit window',
    visitingRegisterInterest: 'Register interest',
    visitingBookScreening: 'Book a screening',
    visitingInterestDone:
        'Your interest is registered. We will contact you to arrange screening.',
    visitingSeats: 'Places available',
    visitingStageInterest: 'Interest registered',
    visitingStageScreening: 'Screening booked',
    visitingStageShortlisted: 'Shortlisted',
    visitingStageScheduled: 'Surgery scheduled',
    visitingStageWaitlisted: 'Waitlisted',
    homeCareTitle: 'Home care',
    homeCareRequest: 'Request service',
    homeCareCoverage: 'Coverage area',
    complaintsTitle: 'Complaints',
    complaintsNew: 'New complaint',
    complaintsCategory: 'Category',
    complaintsBody: 'Details',
    complaintsAnonymous: 'Submit anonymously',
    complaintsAnonymousNote:
        'Anonymous complaints cannot be tracked and you will not receive a response.',
    complaintsSubmit: 'Submit complaint',
    complaintsReference: 'Reference number',
    complaintsSla: 'We acknowledge within 24 hours and respond within 72 hours',
    offersTitle: 'Offers',
    offersEvents: 'Events',
    offersValidUntil: 'Valid until',
    offersBefore: 'Before',
    offersAfter: 'After',
    tipsTitle: 'Medical tips',
    tipsDisclaimer:
        'This is general health information and is not a substitute for medical consultation.',
    tipsReviewedBy: 'Medically reviewed',
    contactTitle: 'Contact us',
    contactCall: 'Call',
    contactWhatsapp: 'WhatsApp',
    contactAmbulance: 'Request ambulance',
    contactAmbulanceNote:
        'The phone call is the authoritative emergency channel. The in-app request is supplementary.',
    contactDirections: 'Directions',
    moreTitle: 'More',
    moreLanguage: 'Language',
    moreAppearance: 'Appearance',
    moreNotifications: 'Notifications',
    morePrivacy: 'Privacy & consent',
    moreAbout: 'About',
    moreSignOut: 'Sign out',
    moreSignIn: 'Sign in',
    aboutDevelopedBy: 'Developed by',
    aboutVisitWebsite: 'Visit website',
    aboutSupport: 'Support',
    themeSystem: 'System',
    themeLight: 'Light',
    themeDark: 'Dark',
    guestBannerTitle: 'You are browsing as a guest',
    guestBannerBody:
        'Sign in to book appointments and view your medical file and results.',
    guestBannerAction: 'Sign in',
    approvalsTitle: 'Approvals',
    approvalsPending: 'Pending',
    approvalsDecided: 'Decided',
    approvalsEmpty: 'No requests awaiting approval',
    approvalsApprove: 'Approve',
    approvalsReject: 'Reject',
    approvalsMoreInfo: 'Request more information',
    approvalsRejectReason: 'Reason for rejection',
    approvalsDueIn: 'Due in',
    approvalsOverdue: 'Past the response deadline — escalated to the medical director',
    approvalsRunEscalation: 'Run escalation',
    approvalsEscalated: 'Requests escalated',
    approvalsApprovedNote: 'Approved. We will contact you to arrange a date.',
    approvalsMoreInfoNote: 'Please upload your previous reports and investigations.',
    notificationsEmpty: 'No notifications',
    notificationsNoPhi: 'WhatsApp and SMS messages carry a reference and a link only — never clinical data.',
    channelPush: 'Push',
    channelWhatsapp: 'WhatsApp',
    channelSms: 'SMS',
    channelInApp: 'In-app',
    channelTemplateApproved: 'Approved template',
    homeCareAddress: 'Address',
    homeCareWindow: 'Preferred window',
    homeCareNotes: 'Notes',
    homeCareSubmitted: 'Request received',
    homeCareMyRequests: 'My requests',
    homeCareFreeCancel: 'Free cancellation until the team is dispatched.',
    bloodGroup: 'Blood group',
    bloodComponent: 'Component',
    bloodUnits: 'Units',
    bloodRequiredBy: 'Required by',
    bloodSubmitted: 'Sent to the blood bank',
    bloodLastDonation: 'Last donation',
    bloodNextEligible: 'Next eligible',
    bloodEligibleNow: 'Eligible to donate now',
    bloodAcceptAppeals: 'I agree to receive urgent donation appeals',
    bloodRegistered: 'You are registered as a donor',
    visitingPipeline: 'Pipeline',
    visitingAddPatient: 'Add a patient',
    visitingAddedByDoctor: 'Added by doctor',
    visitingSelfRegistered: 'Self-registered',
    visitingCohortLive: 'Confirmed cases',
    visitingScreeningBooked: 'Screening appointment booked',
    visitingAdvance: 'Advance stage',
    bookingsTitle: 'My bookings',
    bookingsEmpty: 'No bookings yet',
    bookingsUpcoming: 'Upcoming',
    bookingsPast: 'Past',
    adminConsole: 'Admin console',
    adminHomeNote: 'Changes here reach patients and doctors immediately, with no app update.',
    adminAdd: 'Add',
    adminName: 'Name',
    adminTitle: 'Title',
    adminCode: 'Code',
    adminDescription: 'Description',
    adminCategory: 'Category',
    adminPrice: 'Price',
    adminPriceFrom: 'Price from',
    adminPriceTo: 'Price to',
    adminColour: 'Colour',
    adminInactive: 'Inactive',
    adminDelete: 'Delete',
    adminDeleteConfirm: 'Confirm deletion',
    adminEnglishFallback: 'If left empty, the Arabic text is shown.',
    adminNoReleaseNeeded: 'This content publishes without a new store release.',
    adminClassifications: 'Operation classifications',
    adminClassificationsNote: 'Classifications are data, not code — add, edit and deactivate here, and the booking sheet and grid pick it up immediately.',
    adminNewClassification: 'New classification',
    adminEditClassification: 'Edit classification',
    adminSchedulingDefaults: 'Scheduling defaults',
    adminDefaultsNote: 'These pre-fill the booking sheet; the surgeon can still change them.',
    adminAnaesthesia: 'Anaesthesia',
    adminRequiredSeniority: 'Required surgeon seniority',
    adminSeniorityNote: 'A lower-graded surgeon may still book, with a warning to the department head — it is not blocked.',
    adminBloodUnits: 'Blood units reserved',
    adminBloodNote: 'Automatically held at the blood bank for every case in this classification.',
    adminSeniority: 'Grade',
    adminProcedures: 'Procedures',
    adminNewProcedure: 'New procedure',
    adminEditProcedure: 'Edit procedure',
    adminTheatreType: 'Theatre type',
    adminCentre: 'Specialty centre',
    adminNoCentre: 'No centre',
    adminPatientRequestable: 'Patients may request this',
    adminPatientRequestableNote: 'If off, the procedure stays available to doctors only.',
    adminClinics: 'Clinics',
    adminNewClinic: 'New clinic',
    adminEditClinic: 'Edit clinic',
    adminWorkingDays: 'Working days',
    adminDoctors: 'Doctors',
    adminDoctorsCount: 'doctor(s)',
    adminAddDoctorFirst: 'Add a doctor first, from the Doctors section.',
    adminNewDoctor: 'New doctor',
    adminEditDoctor: 'Edit doctor',
    adminDoctorTitle: 'Title',
    adminSpecialty: 'Specialty',
    adminTheatres: 'Operating theatres',
    adminNewTheatre: 'New theatre',
    adminEditTheatre: 'Edit theatre',
    adminOperatingHours: 'Operating hours',
    adminHoursInvalid: 'Closing time must be after opening time.',
    adminTheatreActive: 'Theatre in service',
    adminTheatreActiveNote: 'If off, the theatre cannot be booked.',
    adminOffers: 'Offers & events',
    adminNewOffer: 'New offer',
    adminEditOffer: 'Edit offer',
    adminIsEvent: 'Awareness event',
    adminIsEventNote: 'Events appear in their own section, with no prices.',
    adminTips: 'Medical tips',
    adminNewTip: 'New tip',
    adminEditTip: 'Edit tip',
    adminTipBody: 'Tip text',
    adminReviewerName: 'Medical reviewer',
    adminReviewerRequired: 'A tip cannot be published without a named medical reviewer.',
    doctorRequestTitle: 'Theatre request',
    doctorRequestNew: 'New request',
    doctorRequestNote: 'The administration allocates the theatre, time and price. You are notified with the full detail once it is confirmed.',
    doctorRequestNoteLabel: 'Note to the administration',
    doctorRequestNoteHelp: 'Urgency, equipment needed, any constraint on the date.',
    doctorRequestSend: 'Send request',
    doctorRequestSent: 'Request sent',
    doctorRequestSentBody: 'The administration has been notified. You will be alerted as soon as it is scheduled.',
    scheduleTitle: 'Schedule the operation',
    scheduleRequestedBy: 'Requested by',
    scheduleDate: 'Date',
    scheduleTime: 'Time',
    scheduleConfirmedPrice: 'Confirmed price',
    scheduleConfirmedPriceHelp: 'This is the price the hospital commits to, not the initial estimate.',
    scheduleConfirm: 'Confirm booking',
    scheduleNotifiesDoctor: 'The surgeon and the patient are notified with the booking detail.',
    scheduleDone: 'Booked, and the surgeon has been notified',
    scheduleAction: 'Schedule',
    scheduleQueue: 'Awaiting scheduling',
    requestFromDoctor: 'Doctor request',
    requestFromPatient: 'Patient request',
    adminPolicy: 'Policies & settings',
    policyDirectBooking: 'Doctors book theatres directly',
    policyDirectBookingOn: 'A surgeon takes a slot immediately, subject to the conflict rules. Faster, but scheduling control is decentralised.',
    policyDirectBookingOff: 'The surgeon sends a request and the administration allocates the theatre, time and price. More control, slower.',
    policyNotifyOnChange: 'Notify patients when schedules change',
    policyNotifyOnChangeNote: 'When a clinic day or a doctor shift changes, the affected bookings are cancelled, the patient is told, and they can rebook.',
    policyNotifyOffWarning: 'Turning this off means a patient discovers the cancellation on arrival. Not recommended.',
    policyApprovalWindow: 'Approval window',
    policyApprovalWindowNote: 'After this window a request escalates to the medical director.',
    policyCancellationCutoff: 'Cancellation cut-off',
    policyCancellationNote: 'Up to this long before the appointment, the patient may cancel.',
    policyDefaultPayment: 'Default payment policy',
    adminUsers: 'Users & roles',
    adminNewUser: 'New user',
    adminEditUser: 'Edit user',
    adminRoles: 'Roles',
    adminRolesNote: 'One person may hold several roles; permissions are the union.',
    adminApprovalCoverageThin: 'Only one person can approve surgeries. If they are away, patient requests stall — add a second.',
    adminLinkedDoctor: 'Link to doctor profile',
    adminLinkedDoctorNote: 'Linking lets the account see its own schedule and theatre list.',
    adminAudit: 'Audit log',
    adminAuditEmpty: 'No changes recorded',
    adminAuditNote: 'The log is append-only: entries are never edited or removed.',
    permManageCatalogue: 'Manage catalogue',
    permManageUsers: 'Manage users',
    permApprove: 'Approve surgeries',
    permSchedule: 'Schedule',
    permBookDirect: 'Book directly',
    permOverride: 'Override conflicts',
    permAudit: 'View audit log',
    adminShifts: 'Shifts & capacity',
    adminShiftsNote: 'Set which days the doctor works, the hours, and the maximum patients. The slots offered to patients are generated from this.',
    adminShiftFrom: 'From',
    adminShiftTo: 'To',
    adminMaxPatients: 'Maximum patients',
    adminNoCap: 'No cap',
    adminWeeklyCapacity: 'Weekly capacity',
    adminSlotLength: 'Slot length',
    adminNoShift: 'Not working',
    adminPaymentPolicy: 'Payment policy',
    adminDepositAmount: 'Deposit amount',
    adminAffectedBookings: 'Bookings affected',
    adminAffectedWarning: 'This change cancels these bookings. Each patient is told the appointment is cancelled and the times have moved.',
    adminSaveAnyway: 'Save and cancel them',
    bookingPayNow: 'Pay now',
    bookingPayLater: 'Pay at reception',
    bookingDepositNote: 'The deposit holds your place; the balance is paid at reception.',
    bookingDepositPaid: 'Deposit paid',
    bookingBalanceDue: 'Balance due',
    bookingFreeNote: 'Booking is free; you pay at reception.',
    bookingCancelled: 'Appointment cancelled',
    bookingRebook: 'Book a new time',
    capacityFull: 'Fully booked for this day',
    capacityRemaining: 'places left',
  );

  /// Rejection reasons for a surgery request.
  ///
  /// Admin-managed in production (PROMPT.md §6.13.6) — this list is a seed for
  /// the demo, and the approver must always choose one, never a bare "no".
  List<String> get approvalsRejectReasons => localeName == 'en'
      ? const [
          'Patient not clinically fit at present',
          'Further investigations required first',
          'Not indicated — a clinic consultation is advised',
          'Capacity unavailable in the requested period',
          'Financial or insurance approval outstanding',
        ]
      : const [
          'الحالة غير مؤهلة طبيًا في الوقت الحالي',
          'مطلوب استكمال فحوصات قبل اتخاذ القرار',
          'العملية غير مستدعاة — يُنصح بحجز عيادة استشارة',
          'لا توجد سعة متاحة في الفترة المطلوبة',
          'بانتظار الموافقة المالية أو التأمينية',
        ];

  static AppStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'en' ? en : ar;
  }
}

/// Shorthand: `context.s.clinicsTitle`.
extension AppStringsX on BuildContext {
  AppStrings get s => AppStrings.of(this);
}
