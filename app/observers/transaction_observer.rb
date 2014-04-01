# See http://rails-bestpractices.com/posts/19-use-observer
#
# == License:
# Fairnopoly - Fairnopoly is an open-source online marketplace.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Fairnopoly.
#
# Fairnopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairnopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairnopoly.  If not, see <http://www.gnu.org/licenses/>.
#

class TransactionObserver < ActiveRecord::Observer
  def after_buy transaction, transition
    if !transaction.multiple? && transaction.sold?

      if !transaction.purchase_emails_sent
        # Send an email to the seller
        TransactionMailerWorker.perform_in 5.seconds, transaction.id, :seller

        # Send a confirmation email to the buyer
        TransactionMailerWorker.perform_in 5.seconds, transaction.id, :buyer

        transaction.update_attribute :purchase_emails_sent, true
      end

      # check if this article is discountable and reply accordingly
      Discount.discount_chain( transaction ) if transaction.article_discount_id
      FastbillWorker.perform_in 5.seconds, transaction.id

    end
  end

end