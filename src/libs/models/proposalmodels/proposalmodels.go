package proposalmodels

import (
	"context"
	"cos-backend-com/src/common/dbconn"
	"cos-backend-com/src/common/util"
	"cos-backend-com/src/libs/models"
	coresSdk "cos-backend-com/src/libs/sdk/cores"
	"github.com/jmoiron/sqlx"
)

var Proposals = &proposals{
	Connector: models.DefaultConnector,
}

type proposals struct {
	dbconn.Connector
}

func (c *proposals) CreateProposal(ctx context.Context, input *coresSdk.CreateProposalInput, output *coresSdk.CreateProposalResult) (err error) {
	stmt := `
		INSERT INTO proposals(tx_id, startup_id, wallet_addr, contract_addr, status, title, type, user_id, contact, description,
							  voter_type, support_percentage, minimum_approval_percentage, duration, has_payment, payment_addr,
							  payment_type, payment_months, payment_date, payment_amount, total_payment_amount)
		VALUES (${txId}, ${startupId}, ${walletAddr}, ${contractAddr}, ${status}, ${title}, ${type}, ${userId}, ${contact}, ${description},
				${voterType}, ${supportPercentage}, ${minimumApprovalPercentage}, ${duration}, ${hasPayment}, ${paymentAddr},
				${paymentType}, ${paymentMonths}, ${paymentDate}, ${paymentAmount}, ${totalPaymentAmount})
		RETURNING id, status;
	`
	query, args := util.PgMapQuery(stmt, map[string]interface{}{
		"{txId}":                      input.TxId,
		"{startupId}":                 input.StartupId,
		"{walletAddr}":                input.WalletAddr,
		"{contractAddr}":              input.ContractAddr,
		"{status}":                    input.Status,
		"{title}":                     input.Title,
		"{type}":                      input.Type,
		"{userId}":                    input.UserId,
		"{contact}":                   input.Contact,
		"{description}":               input.Description,
		"{voterType}":                 input.VoterType,
		"{supportPercentage}":         input.SupportPercentage,
		"{minimumApprovalPercentage}": input.MinimumApprovalPercentage,
		"{duration}":                  input.Duration,
		"{hasPayment}":                input.HasPayment,
		"{paymentAddr}":               input.PaymentAddr,
		"{paymentType}":               input.PaymentType,
		"{paymentMonths}":             input.PaymentMonths,
		"{paymentDate}":               input.PaymentDate,
		"{paymentAmount}":             input.PaymentAmount,
		"{totalPaymentAmount}":        input.TotalPaymentAmount,
	})

	return c.Invoke(ctx, func(db *sqlx.Tx) error {
		return db.GetContext(ctx, output, query, args...)
	})
}

func (c *proposals) UpdateProposalStatus(ctx context.Context, input *coresSdk.UpdateProposalStatusInput, output *coresSdk.UpdateProposalStatusResult) (err error) {
	stmt := `
		UPDATE proposals set status=${status} where id=${id}
		RETURNING id;
	`
	query, args := util.PgMapQuery(stmt, map[string]interface{}{
		"{status}": input.Status,
		"{id}":     input.Id,
	})
	return c.Invoke(ctx, func(db *sqlx.Tx) error {
		return db.GetContext(ctx, output, query, args...)
	})
}

func (c *proposals) VoteProposal(ctx context.Context, input *coresSdk.VoteProposalInput, output *coresSdk.VoteProposalResult) (err error) {
	stmt := `
		INSERT INTO proposal_votes(tx_id, proposal_id, amount vote_type, wallet_addr, create_at)
		VALUES (${txId}, ${proposalId}, ${amount}, ${voteType}, ${walletAddr}, ${createAt})
	`
	var voteType int
	if input.IsApproved {
		voteType = 1
	} else {
		voteType = 2
	}
	query, args := util.PgMapQuery(stmt, map[string]interface{}{
		"{txId}":       input.TxId,
		"{proposalId}": input.Id,
		"{amount}":     input.Amount,
		"{voteType}":   voteType,
		"{walletAddr}": input.WalletAddr,
		"{createAt}":   input.CreatedAt,
	})
	return c.Invoke(ctx, func(db *sqlx.Tx) error {
		return db.GetContext(ctx, output, query, args...)
	})
}
