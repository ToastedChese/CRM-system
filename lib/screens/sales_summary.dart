import 'package:flutter/material.dart';
class SalesSummary extends StatefulWidget {
	const SalesSummary({super.key});
	@override
		SalesSummaryState createState() => SalesSummaryState();
	}
class SalesSummaryState extends State<SalesSummary> {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: Container(
					constraints: const BoxConstraints.expand(),
					color: Color(0xFFFFFFFF),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: Container(
									color: Color(0xFFFFFFFF),
									width: double.infinity,
									height: double.infinity,
									child: SingleChildScrollView(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												IntrinsicHeight(
													child: Container(
														margin: const EdgeInsets.only( top: 22, bottom: 25, left: 16, right: 16),
														width: double.infinity,
														child: Row(
															mainAxisAlignment: MainAxisAlignment.spaceBetween,
															children: [
																SizedBox(
																	width: 24,
																	height: 24,
																	child: Image.network(
																		"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/t0j31omo_expires_30_days.png",
																		fit: BoxFit.fill,
																	)
																),
																Text(
																	"Sales Summary",
																	style: TextStyle(
																		color: Color(0xFF2023E8),
																		fontSize: 20,
																		fontWeight: FontWeight.bold,
																	),
																),
																SizedBox(
																	width: 24,
																	height: 24,
																	child: Image.network(
																		"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/aiacavum_expires_30_days.png",
																		fit: BoxFit.fill,
																	)
																),
															]
														),
													),
												),
												IntrinsicWidth(
													child: IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 15, left: 16),
															child: Row(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	InkWell(
																		onTap: () { print('Pressed'); },
																		child: IntrinsicWidth(
																			child: IntrinsicHeight(
																				child: Container(
																					decoration: BoxDecoration(
																						borderRadius: BorderRadius.circular(20),
																						color: Color(0xFF0088FF),
																					),
																					padding: const EdgeInsets.only( top: 6, bottom: 6, left: 14, right: 14),
																					margin: const EdgeInsets.only( right: 12),
																					child: Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							Text(
																								"All",
																								style: TextStyle(
																									color: Color(0xFFFFFFFF),
																									fontSize: 14,
																								),
																							),
																						]
																					),
																				),
																			),
																		),
																	),
																	InkWell(
																		onTap: () { print('Pressed'); },
																		child: IntrinsicWidth(
																			child: IntrinsicHeight(
																				child: Container(
																					decoration: BoxDecoration(
																						borderRadius: BorderRadius.circular(20),
																						color: Color(0xFFF6F6F6),
																					),
																					padding: const EdgeInsets.only( top: 6, bottom: 6, left: 14, right: 14),
																					margin: const EdgeInsets.only( right: 12),
																					child: Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							Text(
																								"Installations",
																								style: TextStyle(
																									color: Color(0xFF000000),
																									fontSize: 14,
																								),
																							),
																						]
																					),
																				),
																			),
																		),
																	),
																	InkWell(
																		onTap: () { print('Pressed'); },
																		child: IntrinsicWidth(
																			child: IntrinsicHeight(
																				child: Container(
																					decoration: BoxDecoration(
																						borderRadius: BorderRadius.circular(20),
																						color: Color(0xFFF6F6F6),
																					),
																					padding: const EdgeInsets.only( top: 6, bottom: 6, left: 14, right: 14),
																					child: Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							Text(
																								"Online Orders",
																								style: TextStyle(
																									color: Color(0xFF000000),
																									fontSize: 14,
																								),
																							),
																						]
																					),
																				),
																			),
																		),
																	),
																]
															),
														),
													),
												),
												IntrinsicHeight(
													child: SizedBox(
														width: double.infinity,
														child: SingleChildScrollView(
															scrollDirection: Axis.horizontal,
															child: Row(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	InkWell(
																		onTap: () { print('Pressed'); },
																		child: IntrinsicWidth(
																			child: IntrinsicHeight(
																				child: Container(
																					decoration: BoxDecoration(
																						border: Border.all(
																							color: Color(0xFFDFDFDF),
																							width: 1,
																						),
																						borderRadius: BorderRadius.circular(8),
																						color: Color(0xFFFFFFFF),
																					),
																					padding: const EdgeInsets.symmetric(vertical: 16),
																					margin: const EdgeInsets.only( left: 16, right: 12),
																					child: Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							Container(
																								margin: const EdgeInsets.only( bottom: 8, left: 16, right: 135),
																								child: Text(
																									"Total Profit",
																									style: TextStyle(
																										color: Color(0xFF000000),
																										fontSize: 14,
																										fontWeight: FontWeight.bold,
																									),
																								),
																							),
																							Container(
																								margin: const EdgeInsets.only( bottom: 8, left: 16, right: 59),
																								child: Text(
																									"R45,678.90",
																									style: TextStyle(
																										color: Color(0xFF000000),
																										fontSize: 28,
																										fontWeight: FontWeight.bold,
																									),
																								),
																							),
																							Container(
																								margin: const EdgeInsets.only( left: 16, right: 69),
																								child: Text(
																									"+20% month over month",
																									style: TextStyle(
																										color: Color(0xFF828282),
																										fontSize: 12,
																									),
																								),
																							),
																						]
																					),
																				),
																			),
																		),
																	),
																	InkWell(
																		onTap: () { print('Pressed'); },
																		child: IntrinsicWidth(
																			child: IntrinsicHeight(
																				child: Container(
																					decoration: BoxDecoration(
																						border: Border.all(
																							color: Color(0xFFDFDFDF),
																							width: 1,
																						),
																						borderRadius: BorderRadius.circular(8),
																						color: Color(0xFFFFFFFF),
																					),
																					padding: const EdgeInsets.symmetric(vertical: 16),
																					child: Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							Container(
																								margin: const EdgeInsets.only( bottom: 8, left: 16, right: 135),
																								child: Text(
																									"Total Income",
																									style: TextStyle(
																										color: Color(0xFF000000),
																										fontSize: 14,
																										fontWeight: FontWeight.bold,
																									),
																								),
																							),
																							Container(
																								margin: const EdgeInsets.only( bottom: 8, left: 16, right: 59),
																								child: Text(
																									"R2,405",
																									style: TextStyle(
																										color: Color(0xFF000000),
																										fontSize: 28,
																										fontWeight: FontWeight.bold,
																									),
																								),
																							),
																							Container(
																								margin: const EdgeInsets.only( left: 16, right: 69),
																								child: Text(
																									"+33% month over month",
																									style: TextStyle(
																										color: Color(0xFF828282),
																										fontSize: 12,
																									),
																								),
																							),
																						]
																					),
																				),
																			),
																		),
																	),
																],
															)
														),
													),
												),
												IntrinsicHeight(
													child: Container(
														decoration: BoxDecoration(
															border: Border.all(
																color: Color(0xFFDFDFDF),
																width: 1,
															),
															borderRadius: BorderRadius.circular(8),
															color: Color(0xFFFFFFFF),
														),
														padding: const EdgeInsets.symmetric(vertical: 16),
														margin: const EdgeInsets.only( bottom: 11, left: 19, right: 19),
														width: double.infinity,
														child: Column(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																Container(
																	margin: const EdgeInsets.only( bottom: 24, left: 16, right: 235),
																	child: Text(
																		"Income Graph",
																		style: TextStyle(
																			color: Color(0xFF000000),
																			fontSize: 14,
																			fontWeight: FontWeight.bold,
																		),
																	),
																),
																Container(
																	decoration: BoxDecoration(
																		borderRadius: BorderRadius.circular(8),
																	),
																	margin: const EdgeInsets.only( bottom: 4, left: 16, right: 16),
																	height: 1,
																	width: double.infinity,
																	child: ClipRRect(
																		borderRadius: BorderRadius.circular(8),
																		child: Image.network(
																			"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/hsg17rmt_expires_30_days.png",
																			fit: BoxFit.fill,
																		)
																	)
																),
																IntrinsicHeight(
																	child: Container(
																		margin: const EdgeInsets.symmetric(horizontal: 16),
																		width: double.infinity,
																		child: Stack(
																			clipBehavior: Clip.none,
																			children: [
																				Column(
																					crossAxisAlignment: CrossAxisAlignment.start,
																					children: [
																						IntrinsicWidth(
																							child: IntrinsicHeight(
																								child: Column(
																									crossAxisAlignment: CrossAxisAlignment.start,
																									children: [
																										Container(
																											margin: const EdgeInsets.only( bottom: 5, right: 277),
																											child: Text(
																												"R50 000",
																												style: TextStyle(
																													color: Color(0xFF828282),
																													fontSize: 10,
																												),
																											),
																										),
																										IntrinsicWidth(
																											child: IntrinsicHeight(
																												child: Stack(
																													clipBehavior: Clip.none,
																													children: [
																														Column(
																															crossAxisAlignment: CrossAxisAlignment.start,
																															children: [
																																Container(
																																	decoration: BoxDecoration(
																																		borderRadius: BorderRadius.circular(8),
																																	),
																																	width: 301,
																																	height: 157,
																																	child: ClipRRect(
																																		borderRadius: BorderRadius.circular(8),
																																		child: Image.network(
																																			"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/8n4q64ep_expires_30_days.png",
																																			fit: BoxFit.fill,
																																		)
																																	)
																																),
																															]
																														),
																														Positioned(
																															top: 13,
																															left: 0,
																															right: 0,
																															height: 1,
																															child: Container(
																																decoration: BoxDecoration(
																																	borderRadius: BorderRadius.circular(8),
																																),
																																width: 311,
																																height: 1,
																																child: ClipRRect(
																																	borderRadius: BorderRadius.circular(8),
																																	child: Image.network(
																																		"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/miuwkmwj_expires_30_days.png",
																																		fit: BoxFit.fill,
																																	)
																																)
																															),
																														),
																														Positioned(
																															top: 49,
																															left: 0,
																															right: 0,
																															height: 1,
																															child: Container(
																																decoration: BoxDecoration(
																																	borderRadius: BorderRadius.circular(8),
																																),
																																width: 311,
																																height: 1,
																																child: ClipRRect(
																																	borderRadius: BorderRadius.circular(8),
																																	child: Image.network(
																																		"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/fm6h2vye_expires_30_days.png",
																																		fit: BoxFit.fill,
																																	)
																																)
																															),
																														),
																														Positioned(
																															bottom: 72,
																															left: 0,
																															right: 0,
																															height: 1,
																															child: Container(
																																decoration: BoxDecoration(
																																	borderRadius: BorderRadius.circular(8),
																																),
																																width: 311,
																																height: 1,
																																child: ClipRRect(
																																	borderRadius: BorderRadius.circular(8),
																																	child: Image.network(
																																		"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/aa7hy9xw_expires_30_days.png",
																																		fit: BoxFit.fill,
																																	)
																																)
																															),
																														),
																														Positioned(
																															bottom: 36,
																															left: 0,
																															right: 0,
																															height: 1,
																															child: Container(
																																decoration: BoxDecoration(
																																	borderRadius: BorderRadius.circular(8),
																																),
																																width: 311,
																																height: 1,
																																child: ClipRRect(
																																	borderRadius: BorderRadius.circular(8),
																																	child: Image.network(
																																		"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/eq21rvde_expires_30_days.png",
																																		fit: BoxFit.fill,
																																	)
																																)
																															),
																														),
																													]
																												),
																											),
																										),
																									]
																								),
																							),
																						),
																					]
																				),
																				Positioned(
																					top: 4,
																					right: 0,
																					width: 30,
																					height: 30,
																					child: Container(
																						decoration: BoxDecoration(
																							borderRadius: BorderRadius.circular(8),
																						),
																						width: 30,
																						height: 30,
																						child: ClipRRect(
																							borderRadius: BorderRadius.circular(8),
																							child: Image.network(
																								"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/px0xiwfb_expires_30_days.png",
																								fit: BoxFit.fill,
																							)
																						)
																					),
																				),
																			]
																		),
																	),
																),
																Container(
																	decoration: BoxDecoration(
																		borderRadius: BorderRadius.circular(8),
																	),
																	margin: const EdgeInsets.only( bottom: 4, left: 16, right: 16),
																	height: 1,
																	width: double.infinity,
																	child: ClipRRect(
																		borderRadius: BorderRadius.circular(8),
																		child: Image.network(
																			"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/o9zs4z1i_expires_30_days.png",
																			fit: BoxFit.fill,
																		)
																	)
																),
																IntrinsicHeight(
																	child: Container(
																		margin: const EdgeInsets.symmetric(horizontal: 16),
																		width: double.infinity,
																		child: Row(
																			children: [
																				Text(
																					"Nov 23",
																					style: TextStyle(
																						color: Color(0xFF828282),
																						fontSize: 10,
																					),
																				),
																				Expanded(
																					child: SizedBox(
																						width: double.infinity,
																						child: SizedBox(),
																					),
																				),
																				Container(
																					margin: const EdgeInsets.only( right: 29),
																					child: Text(
																						"24",
																						style: TextStyle(
																							color: Color(0xFF828282),
																							fontSize: 10,
																						),
																					),
																				),
																				Container(
																					margin: const EdgeInsets.only( right: 29),
																					child: Text(
																						"25",
																						style: TextStyle(
																							color: Color(0xFF828282),
																							fontSize: 10,
																						),
																					),
																				),
																				Container(
																					margin: const EdgeInsets.only( right: 29),
																					child: Text(
																						"26",
																						style: TextStyle(
																							color: Color(0xFF828282),
																							fontSize: 10,
																						),
																					),
																				),
																				Container(
																					margin: const EdgeInsets.only( right: 28),
																					child: Text(
																						"27",
																						style: TextStyle(
																							color: Color(0xFF828282),
																							fontSize: 10,
																						),
																					),
																				),
																				Container(
																					margin: const EdgeInsets.only( right: 29),
																					child: Text(
																						"28",
																						style: TextStyle(
																							color: Color(0xFF828282),
																							fontSize: 10,
																						),
																					),
																				),
																				Container(
																					margin: const EdgeInsets.only( right: 29),
																					child: Text(
																						"29",
																						style: TextStyle(
																							color: Color(0xFF828282),
																							fontSize: 10,
																						),
																					),
																				),
																				Text(
																					"30",
																					style: TextStyle(
																						color: Color(0xFF828282),
																						fontSize: 10,
																					),
																				),
																			]
																		),
																	),
																),
															]
														),
													),
												),
												IntrinsicHeight(
													child: Container(
														decoration: BoxDecoration(
															border: Border.all(
																color: Color(0xFFD9D9D9),
																width: 1,
															),
															borderRadius: BorderRadius.circular(8),
															color: Color(0xFFFFFFFF),
														),
														padding: const EdgeInsets.symmetric(vertical: 24),
														margin: const EdgeInsets.only( bottom: 54, left: 19, right: 19),
														width: double.infinity,
														child: Column(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																Container(
																	margin: const EdgeInsets.only( bottom: 8, left: 24, right: 194),
																	child: Text(
																		"Latest Sale",
																		style: TextStyle(
																			color: Color(0xFF216EB6),
																			fontSize: 24,
																			fontWeight: FontWeight.bold,
																		),
																	),
																),
																IntrinsicWidth(
																	child: IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.only( left: 24),
																			child: Column(
																				crossAxisAlignment: CrossAxisAlignment.start,
																				children: [
																					Text(
																						"Automation 2.0",
																						style: TextStyle(
																							color: Color(0xFF757575),
																							fontSize: 16,
																						),
																					),
																					Container(
																						margin: const EdgeInsets.only( left: 3, right: 60),
																						child: Text(
																							"R2300",
																							style: TextStyle(
																								color: Color(0xFF17D724),
																								fontSize: 17,
																							),
																						),
																					),
																				]
																			),
																		),
																	),
																),
															]
														),
													),
												),
												IntrinsicHeight(
													child: Container(
														color: Color(0xFFFFFFFF),
														padding: const EdgeInsets.only( left: 7, right: 7),
														width: double.infinity,
														child: Column(
															children: [
																IntrinsicHeight(
																	child: Container(
																		margin: const EdgeInsets.only( bottom: 21),
																		width: double.infinity,
																		child: Row(
																			crossAxisAlignment: CrossAxisAlignment.start,
																			children: [
																				Container(
																					margin: const EdgeInsets.only( right: 20),
																					width: 76,
																					height: 49,
																					child: Image.network(
																						"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/gu2qh0v5_expires_30_days.png",
																						fit: BoxFit.fill,
																					)
																				),
																				Container(
																					margin: const EdgeInsets.only( right: 17),
																					width: 76,
																					height: 49,
																					child: Image.network(
																						"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/dz9l693a_expires_30_days.png",
																						fit: BoxFit.fill,
																					)
																				),
																				Container(
																					margin: const EdgeInsets.only( right: 19),
																					width: 76,
																					height: 49,
																					child: Image.network(
																						"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/crpfkjx0_expires_30_days.png",
																						fit: BoxFit.fill,
																					)
																				),
																				SizedBox(
																					width: 76,
																					height: 49,
																					child: Image.network(
																						"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/lb4707JFp8/9loyaqdv_expires_30_days.png",
																						fit: BoxFit.fill,
																					)
																				),
																			]
																		),
																	),
																),
																Container(
																	decoration: BoxDecoration(
																		borderRadius: BorderRadius.circular(100),
																		color: Color(0xFF000000),
																	),
																	width: 134,
																	height: 5,
																	child: SizedBox(),
																),
															]
														),
													),
												),
											],
										)
									),
								),
							),
						],
					),
				),
			),
		);
	}
}