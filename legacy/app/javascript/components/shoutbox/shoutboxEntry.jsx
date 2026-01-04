import React from "react";

class ShoutboxEntry extends React.Component {
    render() {
        return (
            <tr className={'shoutboxEntry'}>
                <td className='header'>
                    <a href={this.props.profile_link}>
                           {this.props.login}
                    </a>
                    <div className='timeAgo'>{this.props.timeAgo}</div>
                </td>
                <td className='message'>{this.props.content}</td>
            </tr>
        )
    }
}

export default ShoutboxEntry;
