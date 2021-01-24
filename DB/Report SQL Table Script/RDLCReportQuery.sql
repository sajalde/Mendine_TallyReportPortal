USE [EasyReports3.6]
GO
/****** Object:  Table [dbo].[RDLCReportQuery]    Script Date: 1/21/2021 9:12:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RDLCReportQuery](
	[PK_ReportID] [int] IDENTITY(1,1) NOT NULL,
	[IsReleasedInLive] [bit] NULL,
	[IsActive] [bit] NULL,
	[ReportModule] [varchar](150) NULL,
	[ViewOrder] [int] NULL,
	[ReportName] [varchar](50) NULL,
	[ReportDisplayName] [varchar](150) NULL,
	[ReportURL] [varchar](150) NULL,
	[ReportSQLQuery] [nvarchar](max) NULL,
	[ReportSQLQuery_Full] [nvarchar](max) NULL,
	[ParameterList] [varchar](500) NULL,
	[Version] [int] NULL,
	[Status] [varchar](25) NULL,
 CONSTRAINT [PK_RDLCReportQuery] PRIMARY KEY CLUSTERED 
(
	[PK_ReportID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[RDLCReportQuery] ADD  CONSTRAINT [DF_RDLCReportQuery_IsReleasedInLive]  DEFAULT ((0)) FOR [IsReleasedInLive]
GO
ALTER TABLE [dbo].[RDLCReportQuery] ADD  CONSTRAINT [DF_RDLCReportQuery_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RDLCReportQuery] ADD  CONSTRAINT [DF_RDLCReportQuery_ViewOrder]  DEFAULT ((0)) FOR [ViewOrder]
GO
